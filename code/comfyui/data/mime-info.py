"""Which extensions ComfyUI's input lists can show, on this machine.

`LoadImage`, `LoadVideo` and `LoadAudio` fill their lists with the files of the
input directory whose MIME type starts with image, video or audio, and they get
that type from Python's `mimetypes`, which reads the operating system's table:
the registry on Windows, files such as /etc/mime.types elsewhere. So the answer
is a property of the machine, not of ComfyUI. Printed as information, never
compared, the way lesson 6 prints Canny's hashes.
"""
import mimetypes
import platform
import sys

EXTENSIONS = ['.png', '.jpg', '.webp', '.avif', '.exr', '.tif', '.mp4', '.webm', '.flac', '.glb']


def main():
    mimetypes.init()
    print('info mimetypes on %s, Python %s' % (platform.system(), sys.version.split()[0]))
    for extension in EXTENSIONS:
        mime, _ = mimetypes.guess_type('file' + extension, strict=False)
        listed = mime.split('/')[0] if mime else 'nothing lists it'
        print('info   %-6s %-12s %s' % (extension, mime or '-', listed))


if __name__ == '__main__':
    main()
