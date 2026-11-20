# Story 007 sfx bake: loudness table

From `bake-log.txt` (the real bake of `content/themes/dinosaurs`, 36 files). Every file is normalised by one gain to the
cast class, -20 LUFS: integrated (BS.1770-4, gated) for sounds of 0.4 s or longer, the momentary maximum (400 ms window,
the sound padded with silence to 400 ms) for shorter ones. True peak is 4x oversampled (BS.1770-4 Annex 2 FIR) and must be
<= -1 dBTP. Measured on the PCM before AAC encoding by `LoudnessMeter`. Onsets: RMS of 5 ms blocks, an onset is a block at
>= 3 % of the loudest block after the envelope fell below 1 % (`SfxBake.onsets`); for digits it is the chirp count (AC-19).
For the other kinds it is informational (crack = 3 ticks + 2 peeps = 5; roar and thump = 1).

| File | Duration (s) | Measure | Loudness (LUFS) | Gain (dB) | True peak (dBTP) | Onsets |
|---|---|---|---|---|---|---|
| `sfx/sfx_dino_0_nest_01.caf` | 0.160 | momentary max | -20.00 | +6.57 | -6.59 | 1 |
| `sfx/sfx_dino_1_babies_01.caf` | 0.160 | momentary max | -20.00 | +4.93 | -8.22 | 1 |
| `sfx/sfx_dino_2_babies_01.caf` | 0.330 | momentary max | -20.00 | +1.92 | -11.23 | 2 |
| `sfx/sfx_dino_3_babies_01.caf` | 0.500 | integrated | -20.00 | +1.09 | -12.06 | 3 |
| `sfx/sfx_dino_4_babies_01.caf` | 0.670 | integrated | -20.00 | +0.93 | -12.22 | 4 |
| `sfx/sfx_dino_5_babies_01.caf` | 0.840 | integrated | -20.00 | +1.19 | -11.96 | 5 |
| `sfx/sfx_dino_6_babies_01.caf` | 1.010 | integrated | -20.00 | +1.21 | -11.94 | 6 |
| `sfx/sfx_dino_7_babies_01.caf` | 1.180 | integrated | -20.00 | +1.10 | -12.05 | 7 |
| `sfx/sfx_dino_8_babies_01.caf` | 1.350 | integrated | -20.00 | +1.19 | -11.97 | 8 |
| `sfx/sfx_dino_9_babies_01.caf` | 1.520 | integrated | -20.00 | +1.22 | -11.93 | 9 |
| `sfx/sfx_dino_a_ankylosaurus_01.caf` | 0.850 | integrated | -20.00 | -3.14 | -9.01 | 1 |
| `sfx/sfx_dino_b_brachiosaurus_01.caf` | 1.350 | integrated | -20.00 | +3.77 | -7.76 | 1 |
| `sfx/sfx_dino_c_triceratops_01.caf` | 0.950 | integrated | -20.00 | +6.50 | -7.15 | 1 |
| `sfx/sfx_dino_d_diplodocus_01.caf` | 1.350 | integrated | -20.00 | +3.77 | -7.76 | 1 |
| `sfx/sfx_dino_e_edmontosaurus_01.caf` | 0.330 | momentary max | -20.00 | +3.68 | -7.71 | 2 |
| `sfx/sfx_dino_f_fossil_01.caf` | 0.780 | integrated | -20.00 | +0.70 | -6.96 | 5 |
| `sfx/sfx_dino_g_gallimimus_01.caf` | 0.500 | integrated | -20.00 | +1.89 | -11.27 | 3 |
| `sfx/sfx_dino_h_hadrosaurus_01.caf` | 0.330 | momentary max | -20.00 | +3.68 | -7.71 | 2 |
| `sfx/sfx_dino_i_iguanodon_01.caf` | 0.330 | momentary max | -20.00 | +3.68 | -7.71 | 2 |
| `sfx/sfx_dino_j_juravenator_01.caf` | 0.330 | momentary max | -20.00 | +2.04 | -11.12 | 2 |
| `sfx/sfx_dino_k_kentrosaurus_01.caf` | 0.950 | integrated | -20.00 | +6.50 | -7.15 | 1 |
| `sfx/sfx_dino_l_lambeosaurus_01.caf` | 0.330 | momentary max | -20.00 | +3.68 | -7.71 | 2 |
| `sfx/sfx_dino_m_maiasaura_01.caf` | 0.330 | momentary max | -20.00 | +3.68 | -7.71 | 2 |
| `sfx/sfx_dino_n_nest_01.caf` | 0.780 | integrated | -20.00 | +0.70 | -6.96 | 5 |
| `sfx/sfx_dino_o_oviraptor_01.caf` | 0.500 | integrated | -20.00 | +1.89 | -11.27 | 3 |
| `sfx/sfx_dino_p_tapejara_01.caf` | 0.330 | momentary max | -20.00 | +2.04 | -11.12 | 2 |
| `sfx/sfx_dino_q_quetzalcoatlus_01.caf` | 0.330 | momentary max | -20.00 | +2.04 | -11.12 | 2 |
| `sfx/sfx_dino_r_raptor_01.caf` | 0.330 | momentary max | -20.00 | +3.43 | -9.73 | 2 |
| `sfx/sfx_dino_s_stegosaurus_01.caf` | 0.950 | integrated | -20.00 | +6.50 | -7.15 | 1 |
| `sfx/sfx_dino_t_trex_01.caf` | 1.650 | integrated | -20.00 | +2.20 | -7.79 | 1 |
| `sfx/sfx_dino_u_utahraptor_01.caf` | 0.330 | momentary max | -20.00 | +3.43 | -9.73 | 2 |
| `sfx/sfx_dino_v_velociraptor_01.caf` | 0.330 | momentary max | -20.00 | +3.43 | -9.73 | 2 |
| `sfx/sfx_dino_w_wuerhosaurus_01.caf` | 0.950 | integrated | -20.00 | +6.50 | -7.15 | 1 |
| `sfx/sfx_dino_x_xenoceratops_01.caf` | 0.950 | integrated | -20.00 | +6.50 | -7.15 | 1 |
| `sfx/sfx_dino_y_yutyrannus_01.caf` | 1.650 | integrated | -20.00 | +2.20 | -7.79 | 1 |
| `sfx/sfx_dino_z_zuniceratops_01.caf` | 0.950 | integrated | -20.00 | +6.50 | -7.15 | 1 |

Longest file: 1.650 s (T, Y big roar); 9 chirps: 1.520 s. All <= 2.0 s (V12). Highest true peak: -6.59 dBTP (0, empty nest).

By-ear check (A1/A2, roars "a grumble, not a scream"): NOT DONE in this run. It needs a person listening; to be retained here by the content review.
