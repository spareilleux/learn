// obs-mcp: the Observatory RTX scene as MCP tools for Claude Code (artpass/publish/rtx/NOTES.md).
//
// It speaks MCP over stdio (JSON-RPC 2.0, one message a line) and turns each tool call into a request to
// the player's bridge (rtx_bridge.gd, JSON lines on 127.0.0.1:8798, started by `-- --rtx-bridge`). Shots
// come back as images, so the agent sees the scene; obs_flicker scores moiré and crawling edges from frames
// taken in a row while the eye moves a fixed step a frame. Standard library only.
//
//	go build -o obs-mcp.exe .         then: claude mcp add observatory -- <path>\obs-mcp.exe
//	OBS_BRIDGE=127.0.0.1:8798 (default)
package main

import (
	"bufio"
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/jpeg"
	"image/png"
	"math"
	"net"
	"os"
	"sort"
	"strings"
	"time"
)

const protocolVersion = "2025-06-18"

type rpcRequest struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Method  string          `json:"method"`
	Params  json.RawMessage `json:"params,omitempty"`
}

type tool struct {
	Name        string         `json:"name"`
	Description string         `json:"description"`
	InputSchema map[string]any `json:"inputSchema"`
}

func obj(props map[string]any, required ...string) map[string]any {
	s := map[string]any{"type": "object", "properties": props}
	if len(required) > 0 {
		s["required"] = required
	}
	return s
}

var num = map[string]any{"type": "number"}
var boolean = map[string]any{"type": "boolean"}
var str = map[string]any{"type": "string"}
var vec3 = map[string]any{"type": "array", "items": num, "minItems": 3, "maxItems": 3}
var rect = map[string]any{"type": "array", "items": num, "minItems": 4, "maxItems": 4,
	"description": "[x0, y0, x1, y1] in fractions of the window"}

var tools = []tool{
	{"obs_pose", "Where the agent's eye is: position, yaw, pitch, fov, fps, GPU ms, window size.", obj(nil)},
	{"obs_view", "Move the eye to a named view: hall, hall_axis, wing_mid, wing_gallery, wing_window, terrace, basin, palace, roof_city.",
		obj(map[string]any{"name": str, "secs": num}, "name")},
	{"obs_goto", "Move the eye to pos [x,y,z] (metres; the hall's centre is the origin, y up), looking at look [x,y,z].",
		obj(map[string]any{"pos": vec3, "look": vec3, "secs": num}, "pos")},
	{"obs_turn", "Turn the eye: yaw (degrees, left positive) and pitch (up positive).", obj(map[string]any{"yaw": num, "pitch": num, "secs": num})},
	{"obs_walk", "Move the eye forward/right/up in metres, relative to where it looks (level).",
		obj(map[string]any{"forward": num, "right": num, "up": num, "secs": num})},
	{"obs_look", "Turn the eye to face a point.", obj(map[string]any{"at": vec3, "secs": num}, "at")},
	{"obs_shot", "Take a picture of the view (30 frames settle first) and see it. Returns the image (width px wide, default 1280) " +
		"and its numbers: mean luma, nearly black and nearly white shares, GPU ms, the player's settings. crop: a region at the " +
		"window's own pixels instead of the whole view scaled down (to judge edges, moiré, noise).",
		obj(map[string]any{"name": str, "hud": boolean, "width": num, "crop": rect})},
	{"obs_player", "The native settings. Set any of: pt (path tracing), setting (0 DLAA, 1 Quality, 2 Balanced, 3 Performance, 5 no DLSS), " +
		"fg (frame generation), plain_aa (msaa2, msaa4, msaa8, msaa4smaa, msaa8smaa, taa: the anti-aliasing without DLSS), " +
		"bounces, samples, shelf (reading lamps x), fill (fill lights x), exposure, hud (0 all, 1 badge, 2 none). Returns them all.",
		obj(map[string]any{"pt": boolean, "setting": num, "fg": boolean, "plain_aa": str, "bounces": num, "samples": num,
			"shelf": num, "fill": num, "exposure": num, "hud": num, "settle": num})},
	{"obs_env", "The scene's Environment: with prop (and value) one property read (or set); without, the usual ones (tonemap, glow, fog, SSR, SSAO, SSIL, SDFGI, adjustments, path tracing).",
		obj(map[string]any{"prop": str, "value": map[string]any{}})},
	{"obs_get", "A node's property (node: path from the scene root, '' the observatory; prop may go into a resource: material_override:albedo_color).",
		obj(map[string]any{"node": str, "prop": str}, "prop")},
	{"obs_set", "Set a node's property live (Vector3 as [x,y,z], Color as [r,g,b,a]). Returns before and after.",
		obj(map[string]any{"node": str, "prop": str, "value": map[string]any{}}, "prop", "value")},
	{"obs_find", "Find nodes by name pattern (Godot's * and ?) and class.", obj(map[string]any{"pattern": str, "class": str, "max": num}, "pattern")},
	{"obs_tree", "A node's children, depth levels down.", obj(map[string]any{"node": str, "depth": num})},
	{"obs_flicker", "Moiré and flicker: n frames in a row (default 8) while the eye turns yaw degrees and moves forward metres each frame " +
		"(a sub-pixel step, e.g. yaw 0.004 at 64 degrees of fov on 3840 px is a quarter pixel), and as many at rest first (rest: false skips them). Scores each pixel's second " +
		"difference in time, which a smooth slow move keeps near zero and aliasing does not; returns the scores, the grid " +
		"cells where it is worst, and a heat map over the view.",
		obj(map[string]any{"n": num, "yaw": num, "forward": num, "rect": rect, "name": str, "width": num, "rest": boolean})},
	{"obs_raw", "Any bridge request as JSON (cmd and its fields), for what the other tools do not cover.", obj(map[string]any{"request": map[string]any{"type": "object"}}, "request")},
}

func bridgeAddr() string {
	if a := os.Getenv("OBS_BRIDGE"); a != "" {
		return a
	}
	return "127.0.0.1:8798"
}

// call sends one request to the bridge and waits for its one-line reply.
func call(req map[string]any, timeout time.Duration) (map[string]any, error) {
	c, err := net.DialTimeout("tcp", bridgeAddr(), 3*time.Second)
	if err != nil {
		return nil, fmt.Errorf("no bridge at %s (start Observatory-RTX.exe -- --rtx-bridge): %v", bridgeAddr(), err)
	}
	defer c.Close()
	_ = c.SetDeadline(time.Now().Add(timeout))
	b, _ := json.Marshal(req)
	if _, err := c.Write(append(b, '\n')); err != nil {
		return nil, err
	}
	r := bufio.NewReaderSize(c, 1<<20)
	line, err := r.ReadBytes('\n')
	if err != nil {
		return nil, fmt.Errorf("bridge reply: %v", err)
	}
	var out map[string]any
	if err := json.Unmarshal(line, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func loadPNG(path string) (image.Image, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	return png.Decode(f)
}

// lumaOf: Rec. 709 luma of an 8-bit sRGB pixel, 0..1.
func lumaOf(c color.Color) float32 {
	r, g, b, _ := c.RGBA()
	return float32(0.2126*float64(r)+0.7152*float64(g)+0.0722*float64(b)) / 65535
}

// shrink: box filter to w pixels wide.
func shrink(src image.Image, w int) *image.RGBA {
	sb := src.Bounds()
	if w <= 0 || w >= sb.Dx() {
		dst := image.NewRGBA(image.Rect(0, 0, sb.Dx(), sb.Dy()))
		for y := 0; y < sb.Dy(); y++ {
			for x := 0; x < sb.Dx(); x++ {
				dst.Set(x, y, src.At(sb.Min.X+x, sb.Min.Y+y))
			}
		}
		return dst
	}
	h := int(math.Round(float64(sb.Dy()) * float64(w) / float64(sb.Dx())))
	dst := image.NewRGBA(image.Rect(0, 0, w, h))
	fx := float64(sb.Dx()) / float64(w)
	fy := float64(sb.Dy()) / float64(h)
	for y := 0; y < h; y++ {
		y0, y1 := int(float64(y)*fy), int(float64(y+1)*fy)
		for x := 0; x < w; x++ {
			x0, x1 := int(float64(x)*fx), int(float64(x+1)*fx)
			var r, g, b, n uint64
			for yy := y0; yy < y1; yy++ {
				for xx := x0; xx < x1; xx++ {
					cr, cg, cb, _ := src.At(sb.Min.X+xx, sb.Min.Y+yy).RGBA()
					r += uint64(cr)
					g += uint64(cg)
					b += uint64(cb)
					n++
				}
			}
			if n == 0 {
				n = 1
			}
			dst.SetRGBA(x, y, color.RGBA{uint8(r / n >> 8), uint8(g / n >> 8), uint8(b / n >> 8), 255})
		}
	}
	return dst
}

func cropFrac(src image.Image, r []float64) image.Image {
	b := src.Bounds()
	rr := image.Rect(b.Min.X+int(r[0]*float64(b.Dx())), b.Min.Y+int(r[1]*float64(b.Dy())),
		b.Min.X+int(r[2]*float64(b.Dx())), b.Min.Y+int(r[3]*float64(b.Dy())))
	if s, ok := src.(interface {
		SubImage(image.Rectangle) image.Image
	}); ok {
		return s.SubImage(rr)
	}
	return src
}

func jpegContent(img image.Image) map[string]any {
	var buf bytes.Buffer
	_ = jpeg.Encode(&buf, img, &jpeg.Options{Quality: 85})
	return map[string]any{"type": "image", "mimeType": "image/jpeg", "data": base64.StdEncoding.EncodeToString(buf.Bytes())}
}

func textContent(v any) map[string]any {
	b, _ := json.MarshalIndent(v, "", " ")
	return map[string]any{"type": "text", "text": string(b)}
}

func floats(v any) []float64 {
	a, ok := v.([]any)
	if !ok {
		return nil
	}
	out := make([]float64, 0, len(a))
	for _, x := range a {
		if f, ok := x.(float64); ok {
			out = append(out, f)
		}
	}
	return out
}

func numArg(args map[string]any, key string, def float64) float64 {
	if v, ok := args[key].(float64); ok {
		return v
	}
	return def
}

// worstD2 reads frames taken in a row and returns, per pixel, the worst second difference in time
// d2 = |f(t) - 2 f(t+1) + f(t+2)| (luma 0..1), with the first frame.
func worstD2(paths []string) ([]float32, int, int, image.Image, error) {
	var frames [][]float32
	var w, h int
	var first image.Image
	for _, p := range paths {
		img, err := loadPNG(p)
		if err != nil {
			return nil, 0, 0, nil, err
		}
		b := img.Bounds()
		if first == nil {
			first, w, h = img, b.Dx(), b.Dy()
		}
		if b.Dx() != w || b.Dy() != h {
			return nil, 0, 0, nil, fmt.Errorf("%s is %dx%d, not %dx%d", p, b.Dx(), b.Dy(), w, h)
		}
		f := make([]float32, w*h)
		for y := 0; y < h; y++ {
			for x := 0; x < w; x++ {
				f[y*w+x] = lumaOf(img.At(b.Min.X+x, b.Min.Y+y))
			}
		}
		frames = append(frames, f)
	}
	if len(frames) < 3 {
		return nil, 0, 0, nil, fmt.Errorf("need 3 frames or more, got %d", len(frames))
	}
	heat := make([]float32, w*h)
	for t := 0; t+2 < len(frames); t++ {
		a, b, c := frames[t], frames[t+1], frames[t+2]
		for i := range heat {
			d := a[i] - 2*b[i] + c[i]
			if d < 0 {
				d = -d
			}
			if d > heat[i] {
				heat[i] = d
			}
		}
	}
	return heat, w, h, first, nil
}

// dilate: each pixel's max over its 5 x 5 neighbourhood (a still sequence and a moving one are a pixel
// or two apart where the eye turned).
func dilate(src []float32, w, h int) []float32 {
	tmp := make([]float32, len(src))
	out := make([]float32, len(src))
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			var m float32
			for dx := -2; dx <= 2; dx++ {
				if xx := x + dx; xx >= 0 && xx < w && src[y*w+xx] > m {
					m = src[y*w+xx]
				}
			}
			tmp[y*w+x] = m
		}
	}
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			var m float32
			for dy := -2; dy <= 2; dy++ {
				if yy := y + dy; yy >= 0 && yy < h && tmp[yy*w+x] > m {
					m = tmp[yy*w+x]
				}
			}
			out[y*w+x] = m
		}
	}
	return out
}

// flicker scores a moving sequence: per pixel its worst d2, less what the same view does at rest (the
// beams' pulses, the path tracer's noise) when rest frames are given. Moiré and crawling edges remain.
func flicker(paths, rest []string, width int) ([]map[string]any, error) {
	heat, w, h, first, err := worstD2(paths)
	if err != nil {
		return nil, err
	}
	stats := map[string]any{"frames": len(paths), "size": []int{w, h}}
	if len(rest) > 0 {
		still, rw, rh, _, err := worstD2(rest)
		if err != nil {
			return nil, err
		}
		if rw != w || rh != h {
			return nil, fmt.Errorf("rest frames are %dx%d, moving %dx%d", rw, rh, w, h)
		}
		var raw float64
		for _, v := range heat {
			raw += float64(v)
		}
		stats["mean_worst_d2_before_rest"] = math.Round(raw/float64(len(heat))*100000) / 100000
		var rs float64
		for _, v := range still {
			rs += float64(v)
		}
		stats["mean_worst_d2_at_rest"] = math.Round(rs/float64(len(still))*100000) / 100000
		still = dilate(still, w, h)
		for i := range heat {
			heat[i] -= still[i]
			if heat[i] < 0 {
				heat[i] = 0
			}
		}
	}
	var sum float64
	over := 0
	for _, v := range heat {
		sum += float64(v)
		if v > 0.06 {
			over++
		}
	}
	sorted := append([]float32(nil), heat...)
	sort.Slice(sorted, func(i, j int) bool { return sorted[i] < sorted[j] })
	stats["mean_worst_d2"] = math.Round(sum/float64(len(heat))*100000) / 100000
	stats["share_over_0.06"] = math.Round(float64(over)/float64(len(heat))*100000) / 100000
	stats["p99"] = math.Round(float64(sorted[len(sorted)*99/100])*10000) / 10000
	// The worst cells of a 16 x 9 grid.
	type cell struct {
		X, Y int
		M    float64
	}
	var cells []cell
	gw, gh := 16, 9
	for gy := 0; gy < gh; gy++ {
		for gx := 0; gx < gw; gx++ {
			var s float64
			var n int
			for y := gy * h / gh; y < (gy+1)*h/gh; y++ {
				for x := gx * w / gw; x < (gx+1)*w/gw; x++ {
					s += float64(heat[y*w+x])
					n++
				}
			}
			cells = append(cells, cell{gx, gy, s / math.Max(float64(n), 1)})
		}
	}
	sort.Slice(cells, func(i, j int) bool { return cells[i].M > cells[j].M })
	worst := []map[string]any{}
	for _, c := range cells[:6] {
		worst = append(worst, map[string]any{"rect": []float64{float64(c.X) / 16, float64(c.Y) / 9, float64(c.X+1) / 16, float64(c.Y+1) / 9},
			"mean": math.Round(c.M*10000) / 10000})
	}
	stats["worst_cells"] = worst
	// The heat map: the first frame dimmed, red where the score is high; max-pooled so thin lines survive.
	if width <= 0 || width > w {
		width = min(w, 1280)
	}
	oh := int(math.Round(float64(h) * float64(width) / float64(w)))
	base := shrink(first, width)
	for y := 0; y < oh; y++ {
		for x := 0; x < width; x++ {
			var m float32
			for yy := y * h / oh; yy < (y+1)*h/oh; yy++ {
				for xx := x * w / width; xx < (x+1)*w/width; xx++ {
					if heat[yy*w+xx] > m {
						m = heat[yy*w+xx]
					}
				}
			}
			k := math.Min(float64(m)/0.12, 1)
			c := base.RGBAAt(x, y)
			c.R = uint8(math.Min(255, float64(c.R)*0.45*(1-k)+255*k))
			c.G = uint8(float64(c.G) * 0.45 * (1 - k))
			c.B = uint8(float64(c.B)*0.45*(1-k) + 60*k)
			base.SetRGBA(x, y, c)
		}
	}
	return []map[string]any{textContent(stats), jpegContent(base)}, nil
}

func strs(v any) []string {
	var out []string
	if a, ok := v.([]any); ok {
		for _, x := range a {
			if s, ok := x.(string); ok {
				out = append(out, s)
			}
		}
	}
	return out
}

func handleTool(name string, args map[string]any) ([]map[string]any, error) {
	req := map[string]any{}
	for k, v := range args {
		req[k] = v
	}
	timeout := 60 * time.Second
	switch name {
	case "obs_pose":
		req["cmd"] = "pose"
	case "obs_view", "obs_goto", "obs_turn", "obs_walk", "obs_look", "obs_tree", "obs_find", "obs_get", "obs_set", "obs_env", "obs_player":
		req["cmd"] = strings.TrimPrefix(name, "obs_")
		if name == "obs_view" {
			req["cmd"] = "view"
		}
	case "obs_shot":
		req["cmd"] = "shot"
		delete(req, "width")
		delete(req, "crop")
		reply, err := call(req, timeout)
		if err != nil {
			return nil, err
		}
		path, _ := reply["path"].(string)
		if path == "" {
			return []map[string]any{textContent(reply)}, nil
		}
		img, err := loadPNG(path)
		if err != nil {
			return nil, err
		}
		var view image.Image
		if c := floats(args["crop"]); len(c) == 4 {
			view = shrink(cropFrac(img, c), 0)
		} else {
			view = shrink(img, int(numArg(args, "width", 1280)))
		}
		return []map[string]any{textContent(reply), jpegContent(view)}, nil
	case "obs_flicker":
		req = map[string]any{"cmd": "frames", "n": numArg(args, "n", 8), "yaw": numArg(args, "yaw", 0.004),
			"forward": numArg(args, "forward", 0), "name": args["name"]}
		if r := floats(args["rect"]); len(r) == 4 {
			req["rect"] = r
		}
		if req["name"] == nil {
			req["name"] = "flicker"
		}
		reply, err := call(req, 180*time.Second)
		if err != nil {
			return nil, err
		}
		paths := strs(reply["paths"])
		var rest []string
		if r, ok := args["rest"].(bool); !ok || r {
			req["yaw"], req["forward"], req["name"] = 0.0, 0.0, fmt.Sprint(req["name"], "-rest")
			still, err := call(req, 180*time.Second)
			if err != nil {
				return nil, err
			}
			rest = strs(still["paths"])
		}
		out, err := flicker(paths, rest, int(numArg(args, "width", 1280)))
		if err != nil {
			return nil, err
		}
		return append([]map[string]any{textContent(map[string]any{"dir": reply["dir"], "player": reply["player"]})}, out...), nil
	case "obs_raw":
		r, _ := args["request"].(map[string]any)
		req = r
	default:
		return nil, fmt.Errorf("unknown tool %s", name)
	}
	reply, err := call(req, timeout)
	if err != nil {
		return nil, err
	}
	return []map[string]any{textContent(reply)}, nil
}

func main() {
	in := bufio.NewReaderSize(os.Stdin, 1<<20)
	out := bufio.NewWriter(os.Stdout)
	send := func(v any) {
		b, _ := json.Marshal(v)
		out.Write(b)
		out.WriteByte('\n')
		out.Flush()
	}
	for {
		line, err := in.ReadBytes('\n')
		if len(bytes.TrimSpace(line)) > 0 {
			var req rpcRequest
			if json.Unmarshal(line, &req) == nil && len(req.ID) > 0 {
				resp := map[string]any{"jsonrpc": "2.0", "id": req.ID}
				switch req.Method {
				case "initialize":
					var p struct {
						ProtocolVersion string `json:"protocolVersion"`
					}
					_ = json.Unmarshal(req.Params, &p)
					v := p.ProtocolVersion
					if v == "" {
						v = protocolVersion
					}
					resp["result"] = map[string]any{"protocolVersion": v, "capabilities": map[string]any{"tools": map[string]any{}},
						"serverInfo":   map[string]any{"name": "observatory", "version": "0.1.0"},
						"instructions": "The Observatory RTX scene, seen from inside: start Observatory-RTX.exe -- --rtx-bridge, then move the eye (obs_view, obs_goto, obs_turn), change settings (obs_player, obs_env) and look (obs_shot, obs_flicker)."}
				case "ping":
					resp["result"] = map[string]any{}
				case "tools/list":
					resp["result"] = map[string]any{"tools": tools}
				case "tools/call":
					var p struct {
						Name      string         `json:"name"`
						Arguments map[string]any `json:"arguments"`
					}
					_ = json.Unmarshal(req.Params, &p)
					if p.Arguments == nil {
						p.Arguments = map[string]any{}
					}
					content, err := handleTool(p.Name, p.Arguments)
					if err != nil {
						resp["result"] = map[string]any{"content": []map[string]any{{"type": "text", "text": err.Error()}}, "isError": true}
					} else {
						resp["result"] = map[string]any{"content": content}
					}
				default:
					resp["error"] = map[string]any{"code": -32601, "message": "method not found: " + req.Method}
				}
				send(resp)
			}
		}
		if err != nil {
			return
		}
	}
}
