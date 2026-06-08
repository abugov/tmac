APP_INSTALL_DIR ?= $(HOME)/Applications
LSREGISTER ?= /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

# First-time setup (tmux + plugins + configs).
.PHONY: setup
setup:
	@bash setup.sh

# Release build + publish to ~/Applications/Tmac.app.
.PHONY: app
app:
	@bash build-app.sh release
	@$(MAKE) -s publish

# Debug build (faster) + publish.
.PHONY: app-dev
app-dev:
	@bash build-app.sh debug
	@$(MAKE) -s publish

.PHONY: publish
publish:
	@mkdir -p "$(APP_INSTALL_DIR)"
	@rm -rf "$(APP_INSTALL_DIR)/Tmac.app"
	@cp -R "bin/Tmac.app" "$(APP_INSTALL_DIR)/"
	@"$(LSREGISTER)" -f "$(APP_INSTALL_DIR)/Tmac.app"
	@echo "Published: $(APP_INSTALL_DIR)/Tmac.app"

.PHONY: app-clean
app-clean:
	rm -rf .build bin

# Force the macOS preferences daemon and Shortcuts.app to refresh — fixes
# Tmac missing from Shortcuts' Open App picker.
.PHONY: restart-mac-pref-daemon
restart-mac-pref-daemon:
	@printf "Run 'killall cfprefsd; killall Shortcuts 2>/dev/null; open -a Shortcuts'? [Y/n] "; \
		read ans; \
		case "$$ans" in \
			""|y|Y|yes|YES) killall cfprefsd; killall Shortcuts 2>/dev/null; open -a Shortcuts ;; \
			*) echo "Aborted." ;; \
		esac

# Kill tmux server
.PHONY: kill-tmux
kill-tmux:
	tmux -L tmac kill-server