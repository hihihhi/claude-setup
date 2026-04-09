# Role: Data Scientist / ML Engineer

## Phase Routing

| Trigger | Action |
|---------|--------|
| "model" / "train" / "fine-tune" | `/dev-workflow` Phase 2 (ML) |
| "experiment" / "hypothesis" | `/deep-research` then implement |
| "dataset" / "data pipeline" | `data-quality-checker` then implement |
| "evaluate" / "metrics" / "benchmark" | `/benchmark` or `eval-harness` |
| "notebook" / "analysis" | Jupyter workflow |
| "deploy model" / "serve" | `/ship` (ML serving) |
| "paper" / "literature" | `/deep-research` |
| "visualize" / "plot" | Implement with matplotlib/plotly |
| "forecast" / "predict" | `pytorch-patterns` or TimesFM |

## Priority Skills

| Category | Skills |
|----------|--------|
| ML core | `pytorch-patterns`, `cost-aware-llm-pipeline` |
| Evaluation | `benchmark`, `eval-harness`, `agent-eval` |
| Data | `data-quality-checker`, `pandas-pro` |
| Research | `deep-research`, `last30days`, `exa-search` |
| Experiment | `property-based-testing`, `mutation-testing` |
| LLM/AI | `claude-api`, `fine-tuning-expert`, `rag-architect` |
| MLOps | `docker-patterns`, `deploy-to-vercel` |
| Output | `pdf`, `pptx`, `doc-coauthoring` |

## Preferred Agents

| Agent | Role | Model |
|-------|------|-------|
| Scientist | Experiment design, hypothesis, analysis | Opus |
| Implementer | Model code, data pipelines, training loops | Sonnet |
| Reviewer | Statistical rigor, methodology, reproducibility | Sonnet |

## Workflow

1. **Question**: Define hypothesis or prediction target. Success metric first.
2. **Data**: Assess quality with `data-quality-checker`. Clean, split, version.
3. **Baseline**: Simple model first. Establish performance floor.
4. **Experiment**: One variable at a time. Log everything (MLflow/W&B).
5. **Evaluate**: Multiple metrics. Confidence intervals. Ablation studies.
6. **Iterate**: Improve based on error analysis, not intuition.
7. **Document**: Reproduce recipe, model card, limitations.

## ML Standards
- Reproducibility: seed everything, version data and code.
- No data leakage: splits before any transformation.
- Track experiments: hyperparams, metrics, artifacts.
- Model cards: document training data, performance, limitations, biases.
- Validate assumptions: distribution checks, statistical tests.
- Compute budget: profile before scaling. Start small.

## Key Libraries
- **PyTorch**: primary DL framework. Use `pytorch-patterns` skill.
- **TimesFM**: zero-shot time-series forecasting (Google Research).
- **HuggingFace**: model/dataset hub. MCP connected for search.
- **MLflow**: experiment tracking. `pip install mlflow-mcp`.
- **Jupyter**: notebooks via `mcp-jupyter`. Use for exploration only.
- **Ruff/Pyright**: code quality even in research code.
