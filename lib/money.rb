require "bigdecimal"
require "bigdecimal/util"
require "i18n" rescue LoadError
require "money/currency"
require "money/money"
require "money/deprecations"

require "money/core_extensions" if !defined?($load_money_core_extensions) || $load_money_core_extensions
