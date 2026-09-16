// Lesson 21: an end-to-end test. The page, the IPC, the capabilities and the Rust
// commands are all real: only the user is simulated.
import { $, expect } from "@wdio/globals";

describe("chord explorer", () => {
  it("spells the chord typed in the form", async () => {
    await $("#chord-input").setValue("Am7");
    await $("#chord-form button[type=submit]").click();

    await expect($("#chord-output")).toHaveText("Am7 (minor seventh): A C E G  —  1 b3 5 b7");
  });

  it("shows a Rust error when the quality is unknown", async () => {
    await $("#chord-input").setValue("Cm9");
    await $("#chord-form button[type=submit]").click();

    await expect($("#chord-error")).toHaveText("unknownQuality: unknown chord quality `m9` in `Cm9`");
  });
});
