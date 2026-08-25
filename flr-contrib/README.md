# FLR contribution roadmap

Reusable methods now live in **[FLBacktest](https://github.com/laurieKell/FLBacktest)**
(shared with blueMarine). Do not grow parallel helpers in bimResilience.

| Former bim helper | Now |
|-------------------|-----|
| `projectFixedF` | `FLBacktest::fwdFbar` |
| `annualise` | `FLBacktest::annualise` |
| `fsqMean` | inline `mean(c(fbar(...)))` |

Candidate upstream PRs (beyond FLBacktest) remain documented historically in
`FLCore_annualise.R` / `FLasher_projectFixedF.R` but the **working** shared
API is FLBacktest 0.1.6+.

Architecture: [`docs/app_vs_package.md`](../docs/app_vs_package.md).
