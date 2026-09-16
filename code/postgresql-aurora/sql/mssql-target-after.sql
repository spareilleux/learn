-- Lesson 13: what the target gets after the load. Foreign keys are checked once, on the loaded rows; indexes are
-- built once instead of being updated row by row.
ALTER TABLE migrated.jobs ADD FOREIGN KEY (run_id) REFERENCES migrated.runs;
ALTER TABLE migrated.job_labels ADD FOREIGN KEY (job_id) REFERENCES migrated.jobs;
ALTER TABLE migrated.steps ADD FOREIGN KEY (job_id) REFERENCES migrated.jobs;
ALTER TABLE migrated.notes ADD FOREIGN KEY (run_id) REFERENCES migrated.runs;
-- IX_Jobs_RunId ... INCLUDE (Conclusion) has the same syntax
CREATE INDEX jobs_run_id ON migrated.jobs (run_id) INCLUDE (conclusion);
ANALYZE migrated.runs, migrated.jobs, migrated.job_labels, migrated.steps, migrated.notes;
