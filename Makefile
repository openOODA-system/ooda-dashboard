OODA_COMPILER ?= $(HOME)/.openooda/bin/ooda-compiler
export OODA_COMPILER
OODA_STANDARD_ROOT ?= $(HOME)/.openooda/ooda-standard
export OODA_STANDARD_ROOT
OODA_RUNTIME_ROOT ?= $(HOME)/.openooda/bin
export OODA_RUNTIME_ROOT
OODACODEX ?= $(HOME)/.openooda/AGENTS.md
export OODACODEX
OOHAT ?= $(HOME)/.openooda/bin/ooda-verify
export OOHAT
OO_LIST_AMBIENT_QUOTA ?= 8589934592
export OO_LIST_AMBIENT_QUOTA
OODA_MODCACHE ?= $(CURDIR)/.ooda-cache/modcache
export OODA_MODCACHE
export OODA_NO_JAIL=1

REPO_NAME := ooda-dashboard
VER := 0.1.0
BIN := bin/ooda-dashboard
DIST := dist/ooda-dashboard
WASM := dist/dashboard_ui.wasm
TESTBIN_FUNC := bin/test_functional
TESTBIN_REFUSAL := bin/test_refusal
PERSONAS := ooda-dashboard oodadash
SRC := $(shell find . \( -name '*.oo' -o -name '*.oot' \) -not -path './.git/*' -not -path './bin/*' -not -path './dist/*' -not -path './.ooda-cache/*' | sort)
WASM_SRC := $(sort $(wildcard core/wasm/*.oo))
ENV := OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODA_NO_JAIL=1 \
  OODA_STANDARD_ROOT=$(OODA_STANDARD_ROOT) OODA_RUNTIME_ROOT=$(OODA_RUNTIME_ROOT) \
  OODACODEX=$(OODACODEX) OODA_MODCACHE=$(OODA_MODCACHE)

.PHONY: all build wasm verify test det gate check line-cap file-law academy density vocab shape link-law persona-law install clean

all: build verify test det

build: $(BIN) $(WASM)

wasm: $(WASM)

$(WASM): $(WASM_SRC)
	@mkdir -p dist .ooda-cache
	$(ENV) $(OODA_COMPILER) build core/wasm/dashboard_ui.oo --target wasm32-unknown-unknown --shared -o $(WASM)
	@echo "PASS: built $(WASM)"

$(BIN): $(SRC)
	@mkdir -p bin dist .ooda-cache
	$(ENV) $(OODA_COMPILER) build ./cli/main.oo -o $(BIN)
	@chmod +x $(BIN)
	@cp -f $(BIN) $(DIST)
	@chmod +x $(DIST)
	@./$(BIN) --version < /dev/null | grep -q '$(VER)' || { echo 'FAIL: version check'; exit 1; }
	@echo "PASS: built $(BIN) and $(DIST)"

$(TESTBIN_FUNC): tests/test_functional.oo $(SRC)
	@mkdir -p bin .ooda-cache
	$(ENV) $(OODA_COMPILER) build tests/test_functional.oo -o $(TESTBIN_FUNC)
	@chmod +x $(TESTBIN_FUNC)

$(TESTBIN_REFUSAL): tests/test_refusal.oo $(SRC)
	@mkdir -p bin .ooda-cache
	$(ENV) $(OODA_COMPILER) build tests/test_refusal.oo -o $(TESTBIN_REFUSAL)
	@chmod +x $(TESTBIN_REFUSAL)

line-cap:
	@violations=0; \
	for f in $$(find . \( -name "*.oo" -o -name "*.oot" \) -not -path "./.git/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then echo "VIOLATION: $$f = $$n lines (>256)"; violations=$$((violations+1)); fi; \
		code=$$(grep -vE '^[[:space:]]*(//.*)?$$' "$$f" | grep -cvE '^[[:space:]]*import[[:space:]]+"'); \
		if [ "$$code" = "0" ]; then continue; fi; \
		if [ $$n -lt 16 ]; then echo "VIOLATION: $$f = $$n lines (<16)"; violations=$$((violations+1)); fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations line-cap violations"; exit 1; fi; \
	echo "PASS: line-cap (16..256 lines)"

file-law:
	@forbidden="py rs js ts rb pl json yaml toml c h cpp html"; violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./.github/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./.github/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null); do \
		b=$$(basename "$$f"); \
		if [ "$$b" != "README.md" ] && [ "$$b" != "AGENTS.md" ]; then echo "VIOLATION: .md forbidden: $$f"; violations=$$((violations+1)); fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations file-law violations"; exit 1; fi; \
	echo "PASS: file-law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*"); do \
		h=$$(head -12 "$$f"); missing=""; \
		echo "$$h" | grep -q "^// # " || missing="$$missing title"; \
		echo "$$h" | grep -q "^// Logline:" || missing="$$missing logline"; \
		echo "$$h" | grep -q "^// Setup:" || missing="$$missing setup"; \
		echo "$$h" | grep -q "^// Beats:" || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then echo "FAIL: $$f missing:$$missing"; failures=$$((failures+1)); fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./bin*" -not -path "./dist*" -not -path "./.ooda-cache*" -not -path "./.github*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then echo "VIOLATION: $$d holds $$n pages (>8)"; violations=$$((violations+1)); fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations density violations"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages/dir) holds"

vocab:
	@if grep -rilE "b[l]ackbox|a[u]topsy|c[o]ckpit|f[l]ight|sovereign|Pillar [0-9]|Stage [0-9]|bootstrap|moonshot|dogfight" \
		--include="*.oo" --include="*.oot" --include="*.md" --include="*.pkg" . ; then \
		echo "FAIL: banned vocabulary found"; exit 1; \
	fi; \
	echo "PASS: vocabulary check holds"

shape:
	@mkdir -p .ooda-cache; : > .ooda-cache/shape.now; \
	for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./bin/*"); do \
		awk '/^[[:space:]]*((pub|export)[[:space:]]+)?fn[[:space:]]/ { if (started) { len = NR - start; if (len > 64) print "FNLEN|" FILENAME "|" fn "|" len } started = 1; start = NR; if ($$1 == "pub" || $$1 == "export") fn = $$3; else fn = $$2; gsub(/\(.*/, "", fn) } END { if (started) { len = NR - start + 1; if (len > 64) print "FNLEN|" FILENAME "|" fn "|" len } }' "$$f" >> .ooda-cache/shape.now; \
		n=$$(grep -cE "^[[:space:]]*((pub|export)[[:space:]]+)?fn " "$$f" || true); \
		if [ "$$n" -gt 8 ]; then echo "SHAPE|$$f|-|$$n" >> .ooda-cache/shape.now; fi; \
	done; \
	violations=0; \
	while IFS='|' read -r kind path name value; do \
		[ -z "$$kind" ] && continue; \
		echo "VIOLATION: shape law $$kind|$$path|$$name|$$value"; violations=$$((violations+1)); \
	done < .ooda-cache/shape.now; \
	rm -f .ooda-cache/shape.now; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations shape violations"; exit 1; fi; \
	echo "PASS: shape law holds (<=8 fns/page, <=64 lines/fn)"

link-law:
	@violations=0; \
	for f in $$(find . -type l -not -path "./.git/*" 2>/dev/null); do echo "VIOLATION: symlink $$f"; violations=$$((violations+1)); done; \
	for f in $$(find . -type f -links +1 -not -path "./.git/*" 2>/dev/null); do echo "VIOLATION: hardlink $$f"; violations=$$((violations+1)); done; \
	for f in $$(find dist bin -maxdepth 1 -type f 2>/dev/null); do \
		if [ "$$(stat -c '%h' "$$f")" != "1" ]; then echo "VIOLATION: $$f links != 1"; violations=$$((violations+1)); fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations link-law violations"; exit 1; fi; \
	echo "PASS: link-law holds"

check:
	@find . -name "*.oo" -not -path "./.git/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -print0 | \
		xargs -0 -P 8 -n 1 $(OODA_COMPILER) check > /dev/null
	@rm -rf .ooda-cache/ooda-tmp
	@echo "PASS: ooda-compiler check holds on all .oo files"

verify: line-cap file-law academy density vocab shape link-law check

persona-law: $(BIN)
	@rm -rf .ooda-cache/argv0; mkdir -p .ooda-cache/argv0; fails=0; \
	for p in $(PERSONAS); do \
		cp $(BIN) .ooda-cache/argv0/$$p; \
		.ooda-cache/argv0/$$p --help < /dev/null >/dev/null 2>&1 || { echo "FAIL: argv0 $$p"; fails=$$((fails+1)); }; \
		.ooda-cache/argv0/$$p --definitely-unknown-flag < /dev/null >/dev/null 2>&1; rc=$$?; [ $$rc -eq 2 ] || { echo "FAIL: $$p unknown flag rc=$$rc"; fails=$$((fails+1)); }; \
		.ooda-cache/argv0/$$p --persona $$p < /dev/null >/dev/null 2>&1; rc=$$?; [ $$rc -eq 2 ] || { echo "FAIL: $$p retired persona rc=$$rc"; fails=$$((fails+1)); }; \
	done; \
	for sel in "--persona serve" "--mode serve" "--persona=serve" "--personas" "--list-personas" "--definitely-unknown-flag" "about nosuchtarget"; do \
		./$(BIN) $$sel < /dev/null >/dev/null 2>&1; rc=$$?; [ $$rc -eq 2 ] || { echo "FAIL: '$$sel' rc=$$rc (want 2)"; fails=$$((fails+1)); }; \
	done; \
	cp $(BIN) .ooda-cache/argv0/nosuchd; .ooda-cache/argv0/nosuchd --version < /dev/null >/dev/null 2>&1; rc=$$?; \
	[ $$rc -eq 2 ] || { echo "FAIL: unknown argv0 rc=$$rc (want 2)"; fails=$$((fails+1)); }; \
	rm -rf .ooda-cache/argv0; \
	if [ $$fails -gt 0 ]; then echo "FAIL: $$fails persona-law violations"; exit 1; fi; \
	echo "PASS: persona law holds ($(PERSONAS))"

test: $(BIN) $(WASM) $(TESTBIN_FUNC) $(TESTBIN_REFUSAL) persona-law
	@mkdir -p .ooda-cache
	@test "$$(head -c 4 $(WASM) | od -An -tx1 | tr -d ' \n')" = "0061736d" || { echo "FAIL: bad wasm magic"; exit 1; }
	@if command -v node >/dev/null 2>&1; then \
		node -e 'const fs=require("fs");WebAssembly.instantiate(fs.readFileSync(process.argv[1])).then(({instance})=>{const e=instance.exports,b=Number(e.oo_wasm_scratch_base()),d=new TextDecoder(),s=n=>d.decode(new Uint8Array(e.memory.buffer,b,Number(n)));if(Number(e.oo_dash_abi_version())!==1||Number(e.oo_dash_tab_count())!==7||s(e.oo_dash_regime_label(4n))!=="AIRGAP_LOCKDOWN"||s(e.oo_dash_action_body(2n,0n))!=="action=slot_rollback"||s(e.oo_dash_tab_meta(6n))!=="connect|ooda-connect & Interact"||s(e.oo_dash_interact_body(1n))!=="verb=services&target="||s(e.oo_dash_action_body(11n,0n))!=="action=gpu_profile&target=realm-vfio"||Number(e.oo_wui_capabilities_mask())!==31||Number(e.oo_wui_sdf_round_box_milli(0n,0n,5000n,3000n,500n))>=0||!s(e.oo_wui_wgsl_sdf_shader()).includes("fn sdRoundBox")){process.exit(1);}console.log("PASS: Wasm32 dashboard_ui.wasm V8 contract");});' $(WASM); \
	fi
	@PATH=/nonexistent OODA_LEAK_CHECK=1 $(ENV) ./$(TESTBIN_FUNC) < /dev/null > .ooda-cache/fn.out 2>&1 || { cat .ooda-cache/fn.out; exit 1; }
	@cat .ooda-cache/fn.out && grep -q "PASS: functional 12/12" .ooda-cache/fn.out && echo "PASS: functional suite 12/12 under PATH=/nonexistent (OODA_LEAK_CHECK=1)" || exit 1
	@PATH=/nonexistent OODA_LEAK_CHECK=1 $(ENV) ./$(TESTBIN_REFUSAL) < /dev/null > .ooda-cache/ref.out 2>&1 || { cat .ooda-cache/ref.out; exit 1; }
	@cat .ooda-cache/ref.out && grep -q "PASS: refusal 22/22" .ooda-cache/ref.out && echo "PASS: refusal suite 22/22 under PATH=/nonexistent (OODA_LEAK_CHECK=1)" || exit 1
	@OODA_LEAK_CHECK=1 ./$(BIN) --help < /dev/null > /dev/null
	@OODA_LEAK_CHECK=1 ./$(BIN) --version < /dev/null | grep -q "$(VER)"
	@OODA_LEAK_CHECK=1 ./$(BIN) about --json < /dev/null | grep -q '"component":"ooda-dashboard"'
	@OODA_LEAK_CHECK=1 ./$(BIN) --self-test < /dev/null | grep -q "PASS"
	@OODA_LEAK_CHECK=1 ./$(BIN) snapshot --json < /dev/null | grep -q '"component":"ooda-dashboard"'
	@OODA_LEAK_CHECK=1 ./$(BIN) sse < /dev/null | grep -q "event: dashboard-delta"
	@OODA_LEAK_CHECK=1 ./$(BIN) connect status --json < /dev/null | grep -q '"ooda-dashboard"'
	@OODA_LEAK_CHECK=1 ./$(BIN) interact overview --json < /dev/null | grep -q '"kind":"observe"'
	@OODA_LEAK_CHECK=1 ./$(BIN) status < /dev/null | grep -q "status="
	@OODA_LEAK_CHECK=1 ./$(BIN) verify < /dev/null | grep -q "PASS"
	@echo "ALL TESTS PASSED"

det: $(SRC)
	@mkdir -p bin .ooda-cache
	$(ENV) $(OODA_COMPILER) build ./cli/main.oo -o .ooda-cache/$(REPO_NAME).det-a > /dev/null
	$(ENV) $(OODA_COMPILER) build ./cli/main.oo -o .ooda-cache/$(REPO_NAME).det-b > /dev/null
	$(ENV) $(OODA_COMPILER) build core/wasm/dashboard_ui.oo --target wasm32-unknown-unknown --shared -o .ooda-cache/wasm.det-a > /dev/null
	$(ENV) $(OODA_COMPILER) build core/wasm/dashboard_ui.oo --target wasm32-unknown-unknown --shared -o .ooda-cache/wasm.det-b > /dev/null
	@h1=$$(sha256sum .ooda-cache/$(REPO_NAME).det-a | awk '{print $$1}'); \
	h2=$$(sha256sum .ooda-cache/$(REPO_NAME).det-b | awk '{print $$1}'); \
	echo "$$h1  .ooda-cache/$(REPO_NAME).det-a"; \
	echo "$$h2  .ooda-cache/$(REPO_NAME).det-b"; \
	if [ "$$h1" != "$$h2" ]; then echo "FAIL: builds differ"; exit 1; fi; \
	cmp -s .ooda-cache/wasm.det-a .ooda-cache/wasm.det-b || { echo "FAIL: wasm builds differ"; exit 1; }; \
	echo "PASS: deterministic 2-target build (byte-identical)"

gate:
	$(ENV) $(OOHAT) cycle $(CURDIR) --json < /dev/null

install: $(BIN) $(WASM)
	@mkdir -p $(HOME)/.openooda/bin $(HOME)/.openooda/share/ooda-dashboard
	@cp -f $(DIST) $(HOME)/.openooda/bin/ooda-dashboard.tmp && chmod +x $(HOME)/.openooda/bin/ooda-dashboard.tmp && mv -f $(HOME)/.openooda/bin/ooda-dashboard.tmp $(HOME)/.openooda/bin/ooda-dashboard
	@cp -f $(WASM) $(HOME)/.openooda/share/ooda-dashboard/dashboard_ui.wasm.tmp && mv -f $(HOME)/.openooda/share/ooda-dashboard/dashboard_ui.wasm.tmp $(HOME)/.openooda/share/ooda-dashboard/dashboard_ui.wasm
	@sha256sum $(HOME)/.openooda/bin/ooda-dashboard $(HOME)/.openooda/share/ooda-dashboard/dashboard_ui.wasm

clean:
	@rm -rf bin dist .ooda-cache
