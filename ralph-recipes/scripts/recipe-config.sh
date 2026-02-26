#!/usr/bin/env bash
# Returns recipe configuration as shell variables
# Usage: source recipe-config.sh; get_recipe "tdd"
# Sets: RECIPE_MAX_ITERATIONS, RECIPE_COMPLETION_PROMISE, RECIPE_SKILLS, RECIPE_PROMPT_TEMPLATE

get_recipe() {
  local recipe="$1"
  case "$recipe" in
    tdd)
      RECIPE_MAX_ITERATIONS=15
      RECIPE_COMPLETION_PROMISE="ALL TESTS PASS"
      RECIPE_SKILLS="test-driven-development"
      RECIPE_PROMPT_TEMPLATE='You are in a TDD ralph loop. For the target described below:

1. Write a failing test for the next untested behavior
2. Run the test suite to confirm it fails
3. Write the MINIMAL implementation to make it pass
4. Run the test suite to confirm it passes
5. Refactor if needed (tests must stay green)
6. Repeat until fully tested

When ALL tests pass and coverage is complete, output: <promise>ALL TESTS PASS</promise>

Only output the promise when it is genuinely true. Do not lie to escape the loop.

TARGET: %TARGET%
SCOPE: %SCOPE%'
      ;;
    refactor)
      RECIPE_MAX_ITERATIONS=20
      RECIPE_COMPLETION_PROMISE="REFACTOR COMPLETE"
      RECIPE_SKILLS=""
      RECIPE_PROMPT_TEMPLATE='You are in a refactoring ralph loop. For the target described below:

1. Run the full test suite first — all tests MUST pass before any changes
2. Make ONE focused refactoring improvement
3. Run the test suite — all tests MUST still pass
4. Run typecheck — MUST have no type errors
5. Repeat

Refactoring priorities: extract duplication, simplify conditionals, improve naming, reduce coupling.
Do NOT add features. Do NOT change behavior. Tests are your safety net.

When the code is clean and no more improvements are obvious, output: <promise>REFACTOR COMPLETE</promise>

Only output the promise when it is genuinely true.

TARGET: %TARGET%
SCOPE: %SCOPE%'
      ;;
    greenfield)
      RECIPE_MAX_ITERATIONS=30
      RECIPE_COMPLETION_PROMISE=""
      RECIPE_SKILLS=""
      RECIPE_PROMPT_TEMPLATE='You are in a greenfield ralph loop building something from scratch.

1. Scaffold the project structure if not already done
2. Write a failing test for the next piece of functionality
3. Implement it
4. Run tests to confirm
5. Commit working increments
6. Repeat

WHAT TO BUILD: %TARGET%
CONSTRAINTS: %SCOPE%
DONE WHEN: %DONE_CRITERIA%

When the done criteria are fully met, output: <promise>%COMPLETION_PROMISE%</promise>

Only output the promise when it is genuinely true.'
      ;;
    review)
      RECIPE_MAX_ITERATIONS=10
      RECIPE_COMPLETION_PROMISE="ALL CLEAN"
      RECIPE_SKILLS=""
      RECIPE_PROMPT_TEMPLATE='You are in a code review ralph loop. Run two passes:

PASS 1 — VALIDATOR:
Check for: correctness bugs, logic errors, missing edge cases, security issues, type errors, broken patterns.
Fix any issues found.

PASS 2 — MINIFIER:
Check for: unnecessary complexity, dead code, over-abstraction, verbose patterns that could be simpler.
Simplify where possible without changing behavior.

Run the test suite after each change. Tests MUST pass.

When both passes find zero issues, output: <promise>ALL CLEAN</promise>

Only output the promise when it is genuinely true.

TARGET: %TARGET%
SCOPE: %SCOPE%'
      ;;
    *)
      echo "Unknown recipe: $recipe" >&2
      return 1
      ;;
  esac
}
