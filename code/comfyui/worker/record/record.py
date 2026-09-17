# ComfyUI course, lesson 12: records what a real ComfyUI server answers and sends, so that the fake server
# the worker's tests use replays real shapes instead of shapes guessed from the documentation.
#   python record.py <server> <out dir> <ComfyUI dir> <base dir>   (both directories are hidden in the files)
# It needs aiohttp, which ComfyUI's own requirements install. It uses workflows that need no model, and changes
# nothing on the server but its queue, its history and its output folder.
import asyncio
import json
import pathlib
import sys
import uuid

import aiohttp

SERVER, OUT = sys.argv[1], pathlib.Path(sys.argv[2])
HIDE = {sys.argv[3]: "<ComfyUI>", sys.argv[4]: "<base>"}
HERE = pathlib.Path(__file__).resolve().parent
WORKFLOWS = HERE.parent / "workflows"


def save(name, value):
    text = json.dumps(value, indent=2, ensure_ascii=False)
    # Local paths (tracebacks, argv) say nothing about the protocol.
    for path, label in HIDE.items():
        windows = path.replace("/", "\\")
        for spelling in (path.replace("\\", "/"), windows, json.dumps(windows)[1:-1]):
            text = text.replace(spelling, label)
    (OUT / f"{name}.json").write_text(text + "\n", encoding="utf-8")
    print(f"saved {name}.json")


def workflow(name, **changes):
    path = WORKFLOWS / name if (WORKFLOWS / name).exists() else HERE.parent.parent / "workflows" / name
    prompt = json.loads(path.read_text(encoding="utf-8"))
    for key, value in changes.items():
        node, field = key.split("__")
        prompt[node]["inputs"][field] = value
    return prompt


async def post(session, route, body):
    async with session.post(f"{SERVER}{route}", json=body) as response:
        text = await response.text()
        try:
            parsed = json.loads(text)
        except json.JSONDecodeError:
            parsed = text
        return {"status": response.status, "content_type": response.content_type, "body": parsed}


async def get(session, route):
    async with session.get(f"{SERVER}{route}") as response:
        return {"status": response.status, "content_type": response.content_type, "body": await response.json()}


async def messages_until_idle(ws, prompt_ids, limit=120):
    """Every message until the server says, for each prompt, that nothing is executing any more."""
    left, received = set(prompt_ids), []
    while left:
        message = await ws.receive(timeout=limit)
        if message.type == aiohttp.WSMsgType.TEXT:
            parsed = json.loads(message.data)
            received.append(parsed)
            data = parsed.get("data", {})
            if parsed["type"] == "executing" and data.get("node") is None:
                left.discard(data.get("prompt_id"))
        elif message.type == aiohttp.WSMsgType.BINARY:
            received.append({"binary_bytes": len(message.data)})
        else:
            received.append({"websocket": str(message.type)})
            break
    return received


async def main():
    OUT.mkdir(parents=True, exist_ok=True)
    client_id = uuid.uuid4().hex
    async with aiohttp.ClientSession() as session:
        save("system_stats", await get(session, "/system_stats"))
        save("queue_idle", await get(session, "/queue"))
        async with session.ws_connect(f"{SERVER}/ws?clientId={client_id}") as ws:
            first = json.loads((await ws.receive(timeout=30)).data)
            save("ws_connect", {"client_id": client_id, "first_message": first})

            # A prompt that succeeds, followed to the end, then its history and one of its files
            prompt_id = str(uuid.uuid4())
            answer = await post(session, "/prompt", {"prompt": workflow("solid-color.api.json"), "client_id": client_id, "prompt_id": prompt_id})
            events = await messages_until_idle(ws, [prompt_id])
            history = await get(session, f"/history/{prompt_id}")
            image = next(iter(history["body"][prompt_id]["outputs"].values()))["images"][0]
            async with session.get(f"{SERVER}/view", params={"filename": image["filename"], "subfolder": image["subfolder"], "type": image["type"]}) as view:
                body = await view.read()
                file = {"status": view.status, "content_type": view.content_type, "bytes": len(body), "png_signature": body[:8] == bytes.fromhex("89504e470d0a1a0a")}
            save("success", {"prompt_id": prompt_id, "post_prompt": answer, "messages": events, "history": history, "view": file})

            # The same prompt id posted again, with another input: does the server refuse it?
            again = await post(session, "/prompt", {"prompt": workflow("solid-color.api.json", **{"1__color": 65280}), "client_id": client_id, "prompt_id": prompt_id})
            events = await messages_until_idle(ws, [prompt_id])
            history = await get(session, f"/history/{prompt_id}")
            save("same_prompt_id", {"prompt_id": prompt_id, "post_prompt": again, "messages": events, "history": history})

            # Three prompts at once: one runs, the others wait
            ids = [str(uuid.uuid4()) for _ in range(3)]
            answers = [await post(session, "/prompt", {"prompt": workflow("slow-cpu.api.json", **{"1__color": 1000 + i}), "client_id": client_id, "prompt_id": ids[i]}) for i in range(3)]
            queue = await get(session, "/queue")
            events = await messages_until_idle(ws, ids)
            save("three_prompts", {"prompt_ids": ids, "post_prompt": answers, "queue": queue, "messages": events})

            # A prompt that fails validation, and a prompt id in the wrong form
            broken = await post(session, "/prompt", {"prompt": json.loads((HERE.parent.parent / "workflows" / "03-broken.api.json").read_text(encoding="utf-8")), "client_id": client_id})
            bad_id = await post(session, "/prompt", {"prompt": workflow("solid-color.api.json"), "client_id": client_id, "prompt_id": "NOT-A-UUID"})
            save("validation_error", {"post_prompt": broken, "invalid_prompt_id": bad_id})

            # A prompt that passes validation and fails while running
            failing_id = str(uuid.uuid4())
            answer = await post(session, "/prompt", {"prompt": workflow("execution-error.api.json"), "client_id": client_id, "prompt_id": failing_id})
            events = await messages_until_idle(ws, [failing_id])
            history = await get(session, f"/history/{failing_id}")
            save("execution_error", {"prompt_id": failing_id, "post_prompt": answer, "messages": events, "history": history})

            # A slow prompt, interrupted while it runs
            slow_id = str(uuid.uuid4())
            answer = await post(session, "/prompt", {"prompt": workflow("slow-cpu.api.json", **{"1__color": 4242}), "client_id": client_id, "prompt_id": slow_id})
            received = []
            while True:
                message = json.loads((await ws.receive(timeout=60)).data)
                received.append(message)
                if message["type"] == "executing" and message["data"].get("node") is not None:
                    break
            running = await get(session, "/queue")
            interrupt = await post(session, "/interrupt", {"prompt_id": slow_id})
            received += await messages_until_idle(ws, [slow_id])
            history = await get(session, f"/history/{slow_id}")
            save("interrupted", {"prompt_id": slow_id, "post_prompt": answer, "queue_while_running": running, "post_interrupt": interrupt, "messages": received, "history": history})

        # A body that isn't JSON: the handler raises, and aiohttp answers 500
        async with session.post(f"{SERVER}/prompt", data=b"{not json", headers={"Content-Type": "application/json"}) as response:
            save("server_error", {"status": response.status, "content_type": response.content_type, "body": await response.text()})

        save("other_routes", {
            "history_unknown_id": await get(session, f"/history/{uuid.uuid4()}"),
            "interrupt_not_running": await post(session, "/interrupt", {"prompt_id": str(uuid.uuid4())}),
            "free": await post(session, "/free", {"unload_models": True, "free_memory": True}),
        })


asyncio.run(main())
