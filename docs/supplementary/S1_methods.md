# S1 — Technical methods supplement

Expanded methods for BIM Resilience TAC scenarios. Complements `report/latex/chapter_tac_simulations.tex` and `docs/report_main.md`. Implementation: `R/fcstCtrl.R`, `R/eqRegimes.R`, `R/nephOps.R`, `R/macProjections.R`.

---

## 1. Notation

| Symbol | Meaning |
|--------|---------|
| \(\bar{F}\) / Fbar | Mean fishing mortality over selected ages (FLStock `fbar`) |
| \(F_{\mathrm{sq}}\) | Status-quo *F*: mean Fbar over the last \(n\) assessment years (default \(n=3\)) |
| \(F_{\mathrm{MSY}}\) | Fishing mortality at MSY (from reference-point table / biodyn `fmsy`) |
| \(R\) | Recruitment |
| \(\delta_y\) | Recruitment deviance in year \(y\) (multiplicative on the stock–recruit prediction in `FLasher::fwd`) |
| \(\bar{\delta}_{\mathrm{recent}}\) | Recent residual mean (short window; package uses recentDev / tail of residuals) |
| \(\delta_{\mathrm{regime}}\) | Mean residual on the latest regime segment from `rod()` residual segmentation |
| \(B_{\mathrm{trigger}}\) | MSY \(B_{\mathrm{trigger}}\) (SAG / rfpts); CSV column `Btrig` = \(B/B_{\mathrm{trigger}}\) |
| \(u\) / harvest | Nephrops biodyn harvest rate |
| \(\mathrm{pe}_y\) | Process-error multiplier on the biodyn projection |

Horizons: age-structured and albacore projections to **2050**; Nephrops harvest projections through **2041** (ops `projectionYears = 2027:2040` with `endYear = max(projectionYears)+1`).

---

## 2. Age-structured control table (`buildFcstCtrl`)

For each stock \(s\) and scenario \(c\):

\[
F_{s,c} =
\begin{cases}
F_{\mathrm{sq},s} & c \in \{\text{FStatus Quo},\ \text{FStatus Quo 75\%},\ \text{FStatus Quo 50\%}\} \\
F_{\mathrm{MSY},s} & c \in \{\text{FMSY},\ \text{Regime}\}
\end{cases}
\]

\[
\delta_{s,c} =
\begin{cases}
\bar{\delta}_{\mathrm{recent},s} \times 1.00 & c = \text{FStatus Quo} \\
\bar{\delta}_{\mathrm{recent},s} \times 0.75 & c = \text{FStatus Quo 75\%} \\
\bar{\delta}_{\mathrm{recent},s} \times 0.50 & c = \text{FStatus Quo 50\%} \\
\bar{\delta}_{\mathrm{recent},s} \times 1.00 & c = \text{FMSY} \\
\delta_{\mathrm{regime},s} & c = \text{Regime}
\end{cases}
\]

Projection years \(y = y_{\mathrm{term}}+1,\ldots,2050\):

\[
\texttt{fwdControl}(y,\ \texttt{quant="f"},\ \texttt{value}=F_{s,c}),
\quad
\texttt{deviances}_y = \delta_{s,c}
\quad\text{(constant across } y\text{)}.
\]

Stock–recruit: Beverton–Holt fitted in `calcEq` with \(B_{\mathrm{lim}}\) prior context; residuals segmented by `rod()`; regime means via `calcEqAndRegimes()` → `recCurrent$regime`.

Special case: if mackerel lacks `recentDev`, default `macRecDev = exp(-0.671)` in `buildFcstCtrl`.

---

## 3. Advice bridge

Before forward projection, catches in the bridge years are set from agreed advice (`advice.csv` / local override) so the OM enters the forecast window from a common near-term state rather than only the raw terminal assessment year. Exact bridge years depend on stock group and advice vintage (see each Rmd).

---

## 4. Nephrops PE formulation (`buildNephOps`)

After JABBA conditioning and optional advice `mpb::fwd` on catch, five biodyn projections are built per FU.

### 4.1 Status-quo harvest with deterministic process error

Let \(u_{\mathrm{sq}}\) = mean harvest over `sqYears` (default 2022:2024). For projection years \(Y\):

| Scenario | Harvest | Process error |
|----------|---------|---------------|
| FStatus Quo | \(u_{\mathrm{sq}}\) | \(\mathrm{pe}_y = 1\) |
| FStatus Quo 75% | \(u_{\mathrm{sq}}\) | \(\mathrm{pe}_y = 0.75\) |
| FStatus Quo 50% | \(u_{\mathrm{sq}}\) | \(\mathrm{pe}_y = 0.50\) |

Interpretation: fishing intensity unchanged; productivity progressively poorer via the biodyn process-error multiplier (not a harvest cut).

### 4.2 \(F_{\mathrm{MSY}}\) harvest

| Scenario | Harvest | Process error |
|----------|---------|---------------|
| Fmsy | \(u = f_{\mathrm{msy}}\) from `refpts(bd)` | default / omitted (baseline PE in `mpb::fwd`) |

Note capitalisation: **`Fmsy`** in Nephrops CSVs vs **`FMSY`** in pelagic/demersal.

### 4.3 Autocorrelated process-error path (`PE`)

1. Project (or prepare) under \(f_{\mathrm{msy}}\) harvest.
2. Draw autocorrelated noise with `rlnoise(1, harvest(bdFmsy)[, Y], sd = processErrorSd, b = processErrorB)` (defaults `sd = 0.15`, `b = 0.3` in `03_nephrops.Rmd`).
3. Re-project with harvest \(f_{\mathrm{msy}}\) and `pe = processError`.

There is **no Regime row** in the Nephrops forecast set; residual-regime diagnostics still appear in figures as analogues to age-structured Regime definition.

### 4.4 Coverage

Eight FUs in forecasts; **`nep.fu.16` excluded** (JABBA non-convergence). `Btrig` in `neph-f.csv` is not cross-FU comparable—read within FU relative to 1.

---

## 5. Albacore

ICCAT SS3-conditioned FLStock. After advice bridge, status-quo *F* held forward with recruitment deviance multipliers:

\[
\delta \in \{1.00,\ 0.75,\ 0.50\} \times \text{(baseline residual scale as implemented in } 04\_iccat.Rmd\text{)}.
\]

Horizon: 2050. Export: `iccat-f.csv`.

---

## 6. Mackerel special projections (`macProjections` / `06_mackerel_projections.Rmd`)

All under **status-quo F** from the bridged pelagic OM (`pel-om.RData`). These **supplement** the shared five-row pelagic table; they do not redefine `pel-f.csv`.

### 6.1 Recruitment levels

Constant deviance \(\delta = \bar{\delta}_{\mathrm{recent}} \times \ell\) for

\[
\ell \in \{1,\ 0.75,\ 0.5,\ 0.25\}.
\]

Helper: `projectRecLevels()`.

### 6.2 One-off *M* shock

Baseline and shocked runs share \(F_{\mathrm{sq}}\) and baseline \(\delta\). In the shocked run, natural mortality in a single year \(y^\*\) (default illustration: 2035) is multiplied by \(m_{\mathrm{mul}}\) (default illustration: 5):

\[
M_{a,y^\*} \leftarrow m_{\mathrm{mul}} \, M_{a,y^\*},
\]

then projection continues with baseline *M* thereafter. Helper: `projectMShock()`.

### 6.3 Random recruitment

Year-to-year lognormal noise around the recent residual mean (historical residual SD if `recSd` is `NULL`); example: `niter = 50`, report median and 90% band. Helper: random-recruitment projector in `R/macProjections.R`. Shows spread for resilience planning, not a full MSE.

Beamer panels: `fig_mac_rec.png`, `fig_mac_mshock.png`, `fig_mac_rand.png` (via `05_figs.Rmd`).

---

## 7. Reading rules (technical)

1. Within-stock \(\Delta\) between scenarios isolates the changed control (\(F\) target or \(\delta\) / \(\mathrm{pe}\)).
2. Absolute catch scales are not comparable across `sid` without normalisation (e.g. catch/MSY for Nephrops panels).
3. Fixed controls ⇒ exposure under sustained pressure; not annual HCR advice.
4. Deterministic \(\delta\) / \(\mathrm{pe}\) ⇒ no probability intervals in stage-1 TAC CSVs.

---

## 8. Code pointers

| Topic | Function / file |
|-------|-----------------|
| Control table | `buildFcstCtrl()`, `runFcstCtrl()` — `R/fcstCtrl.R` |
| Equilibria & regimes | `calcEqAndRegimes()` — `R/eqRegimes.R` |
| Nephrops scenarios | `buildNephOps()` — `R/nephOps.R` |
| Mackerel what-ifs | `projectRecLevels()`, `projectMShock()`, … — `R/macProjections.R` |
| Stock list | `bimSids()` — `R/sids.R` |
| CSV builders | `R/tacCsvExports.R` |
