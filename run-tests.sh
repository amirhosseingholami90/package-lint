#!/bin/sh -e

EMACS="${EMACS:=emacs}"

INIT_PACKAGE_EL="(progn
  (require 'package)
  (push '(\"melpa\" . \"http://melpa.org/packages/\") package-archives)
  (package-initialize))"

# Refresh package archives, because the test suite needs to see at least
# package-lint and cl-lib.
"$EMACS" -Q -batch \
         --eval "$INIT_PACKAGE_EL" \
         --eval '(package-refresh-contents)' \
         --eval "(unless (package-installed-p 'cl-lib) (package-install 'cl-lib))"
# Byte compile, failing on byte compiler warnings or errors
"$EMACS" -Q -batch \
         --eval "$INIT_PACKAGE_EL" \
         -l package-lint.el \
         --eval '(setq byte-compile-error-on-warn t)' \
         -f batch-byte-compile \
         package-lint.el package-lint-test.el
# Lint ourselves
# Lint failures are ignored if EMACS_LINT_IGNORE is defined, so that lint
# failures on Emacs 24.2 and below don't cause the tests to fail, as these
# versions have buggy imenu that reports (defvar foo) as a definition of foo.
"$EMACS" -Q -batch \
         --eval "$INIT_PACKAGE_EL" \
         -l package-lint.el \
         -f package-lint-batch-and-exit \
         package-lint.el package-lint-test.el || [ -n "${EMACS_LINT_IGNORE+x}" ]
# Finally, run the testsuite
"$EMACS" -Q -batch \
         --eval "$INIT_PACKAGE_EL" \
         -l package-lint.el \
         -l package-lint-test.el \
         -f ert-run-tests-batch-and-exit
