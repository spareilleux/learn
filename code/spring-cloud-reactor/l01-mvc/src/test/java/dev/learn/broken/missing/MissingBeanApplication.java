package dev.learn.broken.missing;

import dev.learn.scales.ScaleService;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;

// Registers ScaleService by hand but nothing that implements NoteSpeller, which its constructor needs.
@Configuration
@Import(ScaleService.class)
public class MissingBeanApplication {
}
