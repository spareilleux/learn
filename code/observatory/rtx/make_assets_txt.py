"""ASSETS.txt, the scene's asset notices for the native package: the Web distribution's own
(public/demos/observatory/LICENSES.txt in the learn worktree, from "The marble texture" to its end, word
for word), then the credits the Observatory's page carries and that file does not, since the zip travels
without the page. No licence is stated here that the Web publication does not already state.
    py -3.14 make_assets_txt.py <learn worktree> """
import io
import os
import sys

WT = sys.argv[1].rstrip('/\\')
HERE = os.path.dirname(os.path.abspath(__file__))
web = io.open(os.path.join(WT, 'public/demos/observatory/LICENSES.txt'), encoding='utf-8').read().replace('\r\n', '\n')
start = web.index('The marble texture was generated locally')
end = web.index('No model weights are included in this distribution.')
body = web[start:end].rstrip('\n')
page = io.open(os.path.join(WT, 'src/content/docs/observatory/index.md'), encoding='utf-8').read()
# Each credit below is on the page, with the same licence and the same address.
for needle in ('https://www.eso.org/public/images/eso0932a/', 'ESO/S. Brunier', 'https://creativecommons.org/licenses/by/4.0/',
               'https://huggingface.co/Wan-AI/Wan2.2-TI2V-5B', 'https://huggingface.co/google/umt5-xxl',
               'https://huggingface.co/stabilityai/stable-audio-3-small-sfx', 'Powered by Stability AI',
               'https://stability.ai/community-license-agreement', 'https://ai.google.dev/gemma/terms',
               're-projected, reduced and dimmed'):
    assert needle in page, needle
more = '''The Milky Way over the oculus is ESO's panorama by ESO/S. Brunier, under CC BY 4.0, re-projected,
reduced and dimmed:
https://www.eso.org/public/images/eso0932a/
https://creativecommons.org/licenses/by/4.0/

The frieze's moving frescoes are clips generated locally from each panel's own image with Wan 2.2
TI2V-5B and its umT5-XXL text encoder, both licensed Apache-2.0:
https://huggingface.co/Wan-AI/Wan2.2-TI2V-5B
https://huggingface.co/google/umt5-xxl

The sounds chosen by ear (the curio wheel's, the lift's, the hologram's, the frieze's and the
recording's: assets/sfx/PROVENANCE.md in the pack lists them) were generated locally with Stable Audio 3
Small SFX, Powered by Stability AI (Stability AI Community License), and its T5Gemma text encoder (Gemma
Terms of Use). The drone's hum and the other cues were synthesised by scripts written for this scene:
https://huggingface.co/stabilityai/stable-audio-3-small-sfx
https://stability.ai/community-license-agreement
https://ai.google.dev/gemma/terms

The generated textures, images, sounds and the statue are assets. No model weights are included in this
distribution.'''
io.open(os.path.join(HERE, 'ASSETS.txt'), 'w', encoding='utf-8', newline='\n').write(body + '\n\n' + more + '\n')
print('ASSETS.txt:', len((body + more).split('\n')), 'lines')
