-- Conflict resolution actions for merge tool
-- Handles accept current/incoming/both/none actions
local M = {}

-- Import submodules
local tracking = require("vscode-diff.ui.conflict.tracking")
local signs = require("vscode-diff.ui.conflict.signs")
local actions = require("vscode-diff.ui.conflict.actions")
local diffget = require("vscode-diff.ui.conflict.diffget")
local navigation = require("vscode-diff.ui.conflict.navigation")
local keymaps = require("vscode-diff.ui.conflict.keymaps")

-- Wire up cross-module dependencies
signs._set_tracking_module(tracking)
actions._set_tracking_module(tracking)
actions._set_signs_module(signs)
diffget._set_tracking_module(tracking)
diffget._set_signs_module(signs)
navigation._set_tracking_module(tracking)
keymaps._set_tracking_module(tracking)
keymaps._set_actions_module(actions)
keymaps._set_diffget_module(diffget)
keymaps._set_navigation_module(navigation)

-- Delegate to tracking module
M.run_repeatable_action = tracking.run_repeatable_action
M.initialize_tracking = tracking.initialize_tracking

-- Delegate to signs module
M.refresh_all_conflict_signs = signs.refresh_all_conflict_signs
M.setup_sign_refresh_autocmd = signs.setup_sign_refresh_autocmd

-- Delegate to actions module
M.accept_incoming = actions.accept_incoming
M.accept_current = actions.accept_current
M.accept_both = actions.accept_both
M.discard = actions.discard

-- Delegate to diffget module
M.diffget_incoming = diffget.diffget_incoming
M.diffget_current = diffget.diffget_current

-- Delegate to navigation module
M.navigate_next_conflict = navigation.navigate_next_conflict
M.navigate_prev_conflict = navigation.navigate_prev_conflict

-- Delegate to keymaps module
M.setup_keymaps = keymaps.setup_keymaps

return M
