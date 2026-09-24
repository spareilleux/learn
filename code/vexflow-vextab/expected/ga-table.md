| Case | Text | GA `parse` | VexTab 4.0.5 | GA `generate`, read back by GA / by VexTab |
|---|---|---|---|---|
| beginner-c-major | `5/3 4/2 3/0 2/1 1/0` | error, line 1 col. 1 | error, line 1 | — |
| beginner-g-major | `6/3 5/2 4/0 3/0 2/0 1/3` | error, line 1 col. 1 | error, line 1 | — |
| beginner-d-major | `4/0 3/2 2/3 1/2` | error, line 1 col. 1 | error, line 1 | — |
| beginner-a-major | `5/0 4/2 3/2 2/2 1/0` | error, line 1 col. 1 | error, line 1 | — |
| beginner-e-major | `6/0 5/2 4/2 3/1 2/0 1/0` | error, line 1 col. 1 | error, line 1 | — |
| beginner-a-minor | `5/0 4/2 3/2 2/1 1/0` | error, line 1 col. 1 | error, line 1 | — |
| beginner-e-minor | `6/0 5/2 4/2 3/0 2/0 1/0` | error, line 1 col. 1 | error, line 1 | — |
| beginner-d-minor | `4/0 3/2 2/3 1/1` | error, line 1 col. 1 | error, line 1 | — |
| prompt-example | `5/3 4/2 3/0 2/1 1/0` | error, line 1 col. 1 | error, line 1 | — |
| e2e-1 | `6/0 5/2 4/2 4/0 3/2 2/0 2/1 1/0` | error, line 1 col. 1 | error, line 1 | — |
| e2e-2 | `6/0 5/2 4/2` | error, line 1 col. 1 | error, line 1 | — |
| e2e-3 | `1/0 2/1 3/2` | error, line 1 col. 1 | error, line 1 | — |
| unit-1 | `tabstave notation=true`<br/>`notes :q (0/6.3/6)` | ok | ok | error, line 1 col. 51 / ok |
| perf-1 | `tabstave notation=true`<br/>`notes :q 4/4 5/5` | ok | ok | error, line 1 col. 51 / ok |
| ebnf-1 | `tabstave notation=true key=C time=4/4`<br/>`notes :q (C/4.E/4.G/4) (D/4.F/4.A/4) (E/4.G/4.B/4) (F/4.A/4.C/5)` | error, line 1 col. 30 | ok | — |
| ebnf-2 | `tabstave`<br/>`notes 5h6-7/5 ^3^ :8 7/4 6/3 5/2 3v/1` | error, line 2 col. 7 | ok | — |
| ebnf-3 | `tabstave notation=true key=G`<br/>`notes :q (G/4.B/4.D/5) (C/4.E/4.G/4) (D/4.F#/4.A/4) (G/4.B/4.D/5)`<br/>`text :q, G, C, D, G` | error, line 2 col. 2 | ok | — |
| ebnf-4 | `tabstave`<br/>`notes :8 5/3 7b9b7/3 :q 10s12/2 :8 12v/1` | error, line 2 col. 1 | ok | — |
| annotation | `tabstave`<br/>`notes :q 5/5 $Am$` | error, line 2 col. 1 | ok | — |
| articulation | `tabstave notation=true`<br/>`notes :q C/4 $.a./top.$` | error, line 2 col. 10 | ok | — |
| duration-mid-line | `tabstave`<br/>`notes :q 5/3 :8 7/3 5/3` | error, line 2 col. 1 | ok | — |
| flat-at | `tabstave notation=true tablature=false`<br/>`notes :q B@/4` | error, line 2 col. 10 | ok | — |
| flat-b | `tabstave notation=true tablature=false`<br/>`notes :q Bb/4` | ok | error, line 2 | error, line 1 col. 52 / error, line 2 |
| fret-run | `tabstave`<br/>`notes 4-5-6/3` | error, line 2 col. 7 | ok | — |
| key-minor | `tabstave notation=true key=Am`<br/>`notes :q C/4` | error, line 1 col. 29 | ok | — |
| key-time | `tabstave notation=true key=G time=4/4`<br/>`notes :q 5/3` | error, line 1 col. 30 | ok | — |
| open-c-chord | `tabstave notation=true`<br/>`notes :w (0/1.1/2.0/3.2/4.3/5)` | ok | ok | error, line 1 col. 51 / ok |
| tap-prefix | `tabstave`<br/>`notes t12p7p5h7/4` | error, line 2 col. 7 | ok | — |
| technique-ga-order-dash | `tabstave`<br/>`notes 5/3h7-7/3b9b7` | ok | error, line 2 | error, line 1 col. 51 / error, line 2 |
| technique-ga-order | `tabstave`<br/>`notes 5/3h7 7/3b9b7` | error, line 2 col. 13 | error, line 2 | — |
| technique-vextab-order | `tabstave`<br/>`notes 5h7/3 7b9b7/3` | error, line 2 col. 7 | ok | — |
| text-line | `tabstave notation=true`<br/>`notes :h 5/5 7/5`<br/>`text :h,G,C` | ok | ok | error, line 1 col. 51 / ok |
