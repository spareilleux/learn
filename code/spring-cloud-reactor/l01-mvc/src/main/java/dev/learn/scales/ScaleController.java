package dev.learn.scales;

import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

// [ApiController] with [Route("scales")]: the return value is written as JSON.
@RestController
@RequestMapping("/scales")
class ScaleController {

    private final ScaleService scales;
    private final ScalesProperties properties;

    ScaleController(ScaleService scales, ScalesProperties properties) {
        this.scales = scales;
        this.properties = properties;
    }

    // GET /scales/D?mode=dorian, like [HttpGet("{root}")] with a [FromQuery] parameter.
    @GetMapping("/{root}")
    ScaleService.ScaleView scale(@PathVariable String root, @RequestParam Optional<String> mode) {
        return scales.describe(root, mode.orElse(properties.defaultMode()));
    }

    // An RFC 9457 problem, like Results.Problem(...) in ASP.NET Core.
    @ExceptionHandler(IllegalArgumentException.class)
    ProblemDetail badName(IllegalArgumentException e) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, e.getMessage());
        problem.setTitle("Unknown note or mode");
        return problem;
    }
}
