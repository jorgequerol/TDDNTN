# TDDNTN

This repository contains MATLAB prototypes for NTN TDD scheduling aligned to Milestone-2 definitions:
- Per-UE RTT-based GP estimation
- GP modes: `worst`, `min`, `perUE`
- Optional xDL reuse over GP using `halfRTT` rule and SINR gating (`none`/`0`/`3` dB)

## Run smoke simulation

```bash
matlab -batch "run('scripts/run_sim_smoke.m')"
```

Quick non-SLS smoke run that returns `smokeMetrics` in the base workspace.

## SLS demo (requires 5G Toolbox)

```bash
matlab -batch "run('scripts/run_sls_demo.m')"
```

Minimal system-level demo using `nrGNB`/`nrUE`/`wirelessNetworkSimulator` with `NTNCustomScheduler`.

## Reproduce PPT-style sweep results

```bash
matlab -batch "run('scripts/reproduce_ppt_results.m')"
```

This sweep script evaluates `Tframe_ms = [10 20 30 40 182]`, GP mode, xDL enablement, and xDL threshold (`none`, `0`, `3`).
It writes stable artifacts under `results/`:
- `ppt_reproduction_metrics.csv`
- `ppt_reproduction_metrics.mat`
- `ppt_frame_efficiency_vs_tframe.png`
- `ppt_gp_vs_slant_range.png`

## Run tests

```bash
matlab -batch "run('scripts/run_tests.m')"
```

## Which scripts map to PPT plots

- **Frame efficiency / GP overhead / throughput sweeps**: `scripts/reproduce_ppt_results.m`
- **Per-UE GP vs slant range**: `scripts/reproduce_ppt_results.m` (`ppt_gp_vs_slant_range.png`)
- **Scheduler integration sanity check**: `scripts/run_sls_demo.m`
- **Fast logic sanity check**: `scripts/run_sim_smoke.m`

## Main files

- `NTNCustomScheduler.m`: custom `nrScheduler` subclass with GPMode/xDL parameters and DL/UL hooks.
- `+ntn/computeGP.m`: slant range to RTT and GP slots.
- `+ntn/selectGPSlots.m`: GP selection for `worst`/`min`/`perUE`.
- `+ntn/computeXDLReuseSlots.m`: `halfRTT` xDL reuse slot computation.
- `+ntn/buildFramePlan.m`: DL→GPIdle→xDL→UL frame layout.
- `+ntn/isxDLEligible.m`: xDL gating logic.
