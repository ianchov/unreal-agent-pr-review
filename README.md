# unreal-agent-pr-review

Workflows that review pull requests with [Unreal Agent](https://github.com/unreallabsai/unreal-agent).
Each pull request gets a standard review. When it says `Ready to merge`, an adversarial review
follows and leaves out the defects the standard review reports. The review logic, security model, and defaults
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

All three ways need the repository secret `ANTHROPIC_API_KEY`
(Settings → Secrets and variables → Actions). For OpenAI or OpenRouter, see
[Other model providers](#other-model-providers).

## Template repository

1. Click **Use this template** → **Create a new repository**.
2. Add the secret `ANTHROPIC_API_KEY` to the new repository.
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
      OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
      OPENROUTER_API_KEY: ${{ secrets.OPENROUTER_API_KEY }}
```

The caller must grant `contents: read` and `pull-requests: write`. A called workflow cannot get
more permissions than its caller.

Optional inputs, set under `with:`:

| Input | Default | Meaning |
|---|---|---|
| `runs-on` | `'"ubuntu-24.04"'` | Runner labels as JSON, for example `'["self-hosted","linux"]'`. |
| `provider` | `anthropic` | Model provider: `anthropic`, `openai`, or `openrouter`. The variable `UNREAL_AGENT_PROVIDER` takes precedence when set. |
| `model` | `claude-sonnet-5-5` for `anthropic`, `openai/gpt-6-sol` for `openrouter` | Model for the agent and the reviewer check, in the provider's names. Required for `openai`. |
| `max-review-rounds` | `3` | Most agent and reviewer-check rounds per run. |
| `review-timeout-minutes` | `40` | Time limit for all review rounds. |
| `diff-exclude` | empty | Extra paths to leave out of the diff, one git pathspec per line, for example `app/staticfiles`. Common lockfiles are always left out. |
| `adversarial-review` | `true` | Also run the adversarial review in a second job, only when the standard review says `Ready to merge`: three hostile personas (Saboteur, New Hire, Security Auditor), each with at least one finding. It reads the standard review and reports only defects that review missed, and posts a second comment. For any other verdict, its old comment gets a "Not reviewed for commit …" note instead. Set `false` for the standard review only. |
| `skip-renovate` | `true` | Skip pull requests opened by Renovate (`renovate[bot]`) before a runner starts. |

### Other model providers

Set the repository or organization variable `UNREAL_AGENT_PROVIDER` (Settings → Secrets and
variables → Actions → Variables) to `anthropic`, `openai`, or `openrouter`. When it is set, it
takes precedence over the `provider` input, so you can switch providers without editing the
workflow. Add the chosen provider's key as a secret and pass it, as the workflow above does for all
three. A missing key fails the review with the name of the key it needs.

To fix the provider in the workflow instead, set `provider` under `with:`. For OpenRouter, the model
defaults to `openai/gpt-6-sol`:

```yaml
jobs:
  review:
    uses: ianchov/unreal-agent-pr-review/.github/workflows/review.yml@v1
    with:
      provider: openrouter
    secrets:
      OPENROUTER_API_KEY: ${{ secrets.OPENROUTER_API_KEY }}
```

For OpenAI, also set `model` under `with:` to an OpenAI model name such as `gpt-5`. There is no
variable for the model. Pass the secret `OPENAI_API_KEY`.

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
