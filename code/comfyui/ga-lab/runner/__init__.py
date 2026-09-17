"""Guitar Alchemist lab: a batch runner for ComfyUI experiments.

It never starts a ComfyUI server: it talks to the one given with --server, checks a memory rule before each
submission, runs one prompt at a time, and records what each image needs to be reproduced and compared.
"""
