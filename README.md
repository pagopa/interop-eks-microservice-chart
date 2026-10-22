# interop-eks-microservice-chart

## Linting rendered test values

The PR validation workflow renders each `.yaml` file under `tests/helm-unittest`
whose filename does not contain `_test`, `invalid`, `failure` or `fail`.
Each render loads `tests/helm-unittest/common/base.yaml` first, then the folder base discovered by the `*base.yaml` naming convention (if any), 
and finally the selected values file. The complete manifest is validated with yamllint. 
Folder bases are not rendered on their own, because they may intentionally be incomplete.
Each directory may contain at most one `*base.yaml`; multiple bases fail the check rather than introducing an ambiguous merge order. 
Bases are applied only to fixtures in the same directory, not inherited from parent directories, 
so fixtures requiring different bases must be placed in separate directories (for example, PDB e2e fixtures live in `poddisruptionbudget/e2e`).
Suite definitions and `set` overrides are not read; Helm unittest continues to verify those separately.

The check runs entirely in a Bash step in [PR validation](.github/workflows/pr-validation.yaml), using Helm and
yamllint 1.38.0; the same step can be executed locally with these tools installed, from the repository root.

The dedicated [configuration](tests/yamllint/config.yaml) checks YAML syntax, duplicate keys, trailing whitespace and the final newline without imposing
comment, line-length or indentation conventions on generated manifests.
Diagnostics identify the values file and position in the rendered YAML.
Manifests are checked as rendered, without stripping whitespace or reserializing the YAML, including whitespace inside multiline scalar values.

Unlike Helm unittest's template-scoped assertions, this check renders the whole chart for each values file. Rendering errors and lint violations fail the step.
