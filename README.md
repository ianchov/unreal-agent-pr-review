# unreal-agent-pr-review

Workflows that review pull requests with [Unreal Agent](https://github.com/unreallabsai/unreal-agent).
Each pull request gets a standard review. When it finds no P0 or P1 defect, an adversarial review
follows and leaves out the defects the standard review reports. Each review's check fails when its
verdict is "Merge after fixes" or "Needs rework". When a review is wrong, add the label
`review-accepted` (create it once per repository) to the pull request and re-run the failed job: the check then passes with a
notice. Re-running starts a new review. The label stays for later commits too, so remove it once
the pull request no longer needs it. The review logic, security model, and defaults
live in the action
[ianchov/unreal-agent-pr-review-action](https://github.com/ianchov/unreal-agent-pr-review-action),
also on [GitHub Marketplace](https://github.com/marketplace/actions/unreal-agent-pr-review).

This repository gives three ways to add it:

| Way | Use it when |
|---|---|
| [Template repository](#template-repository) | You start a new repository. |
| [Reusable workflow](#reusable-workflow) | You add the review to an existing repository with one job. |
| [Organization workflow template](#organization-workflow-template) | You want it under Actions → New workflow for every repository in your organization. |

To write your own job instead, use the action directly. See its README.

All three ways need one provider key as a repository secret (Settings → Secrets and variables →
Actions): `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, or `OPENAI_API_KEY`. The workflow passes all
three by name and uses the first key that exists, in that order. See
[Other model providers](#other-model-providers) to choose a provider or model.

## Template repository

1. Click **Use this template** → **Create a new repository**.
2. Add one provider key as a secret to the new repository: `ANTHROPIC_API_KEY`,
   `OPENROUTER_API_KEY`, or `OPENAI_API_KEY`.
3. Delete the `workflow-templates` directory, `.github/workflows/review.yml`, and
   `.github/workflows/install-check.yml`. Your copy uses the reusable workflow from this repository,
   not its own copy. The install check is for this repository only and is skipped in copies.
4. Open a pull request from a branch in the same repository.

## Reusable workflow

Add `.github/workflows/unreal-agent-review.yml`:

```yaml
name: Unreal Agent PR review
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

permissions:
  contents: read
  pull-requests: write

jobs:
  review:
    uses: ianchov/unreal-agent-pr-review/.github/workflows/review.yml@v1
    secrets:
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
      OPENROUTER_API_KEY: ${{ secrets.OPENROUTER_API_KEY }}
      OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

The caller must grant `contents: read` and `pull-requests: write`. A called workflow cannot get
more permissions than its caller.

Optional inputs, set under `with:`:

| Input | Default | Meaning |
|---|---|---|
| `runs-on` | `'"ubuntu-24.04"'` | Runner labels as JSON, for example `'["self-hosted","linux"]'`. |
| `provider` | the first key that exists: `anthropic`, then `openrouter`, then `openai` | Model provider: `anthropic`, `openai`, or `openrouter`. The variable `UNREAL_AGENT_PROVIDER` takes precedence when set. |
| `model` | `claude-sonnet-5-5` for `anthropic`, `openai/gpt-6-sol` for `openrouter` | Model for the agent and the reviewer check, in the provider's names. Required for `openai`. The variable `UNREAL_AGENT_MODEL` takes precedence when set. |
| `max-review-rounds` | `3` | Most agent and reviewer-check rounds per run. |
| `review-timeout-minutes` | `40` | Time limit for all review rounds. |
| `diff-exclude` | empty | Extra paths to leave out of the diff, one git pathspec per line, for example `app/staticfiles`. Common lockfiles are always left out. |
| `adversarial-review` | `true` | Also run the adversarial review in a second job, only when the standard review found no P0 or P1 defect: three hostile personas (Saboteur, New Hire, Security Auditor), each with at least one finding. It reads the standard review and reports only defects that review missed, and posts a second comment. After a P0 or P1 finding, its comment says "not run for commit …" with the reason, and keeps the last adversarial review collapsed. Set `false` for the standard review only. |
| `skip-renovate` | `true` | Skip pull requests opened by Renovate (`renovate[bot]`) before a runner starts. |

### Other model providers

The provider is chosen in this order:

1. The repository or organization variable `UNREAL_AGENT_PROVIDER` (Settings → Secrets and
   variables → Actions → Variables): `anthropic`, `openai`, or `openrouter`.
2. The `provider` input under `with:`.
3. The first provider key the workflow receives: `ANTHROPIC_API_KEY`, then `OPENROUTER_API_KEY`,
   then `OPENAI_API_KEY`.

The workflow above passes all three keys by name, and a key that does not exist arrives empty. So
adding a key as a repository secret is enough; no workflow edit is needed. The order is fixed, so
a repository with several keys always uses the same provider until you set the variable or input.

Do not use `secrets: inherit`. It sends every repository secret to the external reusable
workflow, while the review needs only the provider keys. A missing key fails the review with the
name of the key it needs.

The model comes from the variable `UNREAL_AGENT_MODEL`, then the `model` input, then the
provider's default: `claude-sonnet-5-5` for `anthropic` and `openai/gpt-6-sol` for `openrouter`.
`openai` has no default model, so it needs one of the two. A model name belongs to one provider,
so when you set the provider, set the model with it. For example, OpenRouter with a fixed model:

```yaml
jobs:
  review:
    uses: ianchov/unreal-agent-pr-review/.github/workflows/review.yml@v1
    with:
      provider: openrouter
      model: openai/gpt-6-sol
    secrets:
      OPENROUTER_API_KEY: ${{ secrets.OPENROUTER_API_KEY }}
```

## Organization workflow template

GitHub shows workflow templates only from an organization's `.github` repository.

1. In your organization, create a public repository named `.github` if it does not exist.
2. Copy the `workflow-templates` directory of this repository into it.
3. Merge to its default branch.
4. In any repository of the organization, open Actions → New workflow and select
   **Unreal Agent PR review**.

See [Creating workflow templates for your organization](https://docs.github.com/en/actions/how-tos/reuse-automations/create-workflow-templates).

## Custom prompt, criteria, and rules

Put these files in your repository. Each one is optional and is read from the PR's base branch.

| Path | Default |
|---|---|
| `.github/unreal-agent/pr-review.md` | [pr-review.md](https://github.com/ianchov/unreal-agent-pr-review-action/blob/v1/defaults/pr-review.md) |
| `.github/unreal-agent/review-criteria.md` | [review-criteria.md](https://github.com/ianchov/unreal-agent-pr-review-action/blob/v1/defaults/review-criteria.md) |
| `.github/unreal-agent/adversarial/pr-review.md` | [adversarial/pr-review.md](https://github.com/ianchov/unreal-agent-pr-review-action/blob/v1/defaults/adversarial/pr-review.md) |
| `.github/unreal-agent/adversarial/review-criteria.md` | [adversarial/review-criteria.md](https://github.com/ianchov/unreal-agent-pr-review-action/blob/v1/defaults/adversarial/review-criteria.md) |
| `AGENTS.md` | No repository rules. |

## License

MIT. See [LICENSE](LICENSE).
