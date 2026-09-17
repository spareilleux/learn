package dev.learn.comfy.worker;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileAlreadyExistsException;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;

import dev.learn.comfy.worker.Jobs.StoredFile;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.node.ObjectNode;

/**
 * Results on a shared directory, one folder per job id. done.json says a job is finished; a claim file, created
 * with CREATE_NEW, lets only one worker run a job at a time. In production: object storage and a unique database key.
 */
public final class ResultStore {
    private final Path root;

    public ResultStore(Path root) {
        this.root = root;
    }

    public Path root() {
        return root;
    }

    public boolean isDone(String jobId) {
        return Files.exists(root.resolve(jobId).resolve("done.json"));
    }

    /** True if this worker now owns the job. A claim older than its lease is taken over: its worker died. */
    public boolean tryClaim(String jobId, String owner, Duration lease) throws IOException {
        Files.createDirectories(root.resolve(jobId));
        Path path = root.resolve(jobId).resolve("claim");
        for (int tries = 0; tries < 2; tries++) {
            try {
                ObjectNode claim = ComfyInstance.JSON.createObjectNode().put("owner", owner).put("expires", Instant.now().plus(lease).toString());
                // CREATE_NEW fails if the file exists, atomically.
                Files.writeString(path, claim.toString(), StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE);
                return true;
            } catch (FileAlreadyExistsException e) {
                JsonNode claim = readClaim(path);
                if (claim == null || Instant.parse(claim.path("expires").asString()).isAfter(Instant.now())) {
                    return false;
                }
                Files.deleteIfExists(path); // expired: try once more
            }
        }
        return false;
    }

    private static JsonNode readClaim(Path path) {
        try {
            JsonNode claim = ComfyInstance.JSON.readTree(Files.readString(path));
            return claim.has("expires") ? claim : null;
        } catch (IOException | JacksonException e) {
            return null; // being written by its owner, or already gone
        }
    }

    public void releaseClaim(String jobId, String owner) throws IOException {
        Path path = root.resolve(jobId).resolve("claim");
        JsonNode claim = readClaim(path);
        if (claim != null && claim.path("owner").asString().equals(owner)) {
            try {
                Files.delete(path);
            } catch (NoSuchFileException e) {
                // already gone
            }
        }
    }

    /** Writes an output file under a temporary name first: a crash never leaves a half file that looks finished. */
    public StoredFile saveFile(String jobId, String node, String name, byte[] bytes) throws IOException {
        Path dir = Files.createDirectories(root.resolve(jobId).resolve("outputs"));
        Path fileName = Path.of(name).getFileName();
        Path target = dir.resolve(node + "-" + fileName);
        Path temp = dir.resolve(target.getFileName() + ".partial");
        Files.write(temp, bytes);
        Files.move(temp, target, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
        return new StoredFile(node, target.getFileName().toString(), bytes.length, sha256(bytes).substring(0, 16));
    }

    public void complete(String jobId, String owner, String instance, int attempt, List<StoredFile> files) throws IOException {
        ObjectNode done = ComfyInstance.JSON.createObjectNode().put("job", jobId).put("worker", owner).put("gpu", instance).put("attempts", attempt);
        var array = done.putArray("files");
        for (StoredFile file : files) {
            array.addObject().put("node", file.node()).put("name", file.name()).put("bytes", file.bytes()).put("sha256", file.sha256());
        }
        Path path = root.resolve(jobId).resolve("done.json");
        Path temp = root.resolve(jobId).resolve("done.json.partial");
        Files.writeString(temp, ComfyInstance.JSON.writerWithDefaultPrettyPrinter().writeValueAsString(done), StandardCharsets.UTF_8);
        Files.move(temp, path, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
        releaseClaim(jobId, owner);
    }

    public void fail(String jobId, String owner, String reason) throws IOException {
        Files.writeString(root.resolve(jobId).resolve("failed.txt"), reason + System.lineSeparator(), StandardCharsets.UTF_8);
        releaseClaim(jobId, owner);
    }

    static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
