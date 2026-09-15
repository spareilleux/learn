package dev.learn.scales;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

// The options pattern: IOptions<ScalesOptions> bound from the "Scales" section, validated at startup.
@ConfigurationProperties("scales")
@Validated
public record ScalesProperties(@NotBlank String defaultMode, @NotNull Spelling spelling) {

    public enum Spelling { SHARPS, FLATS }
}
