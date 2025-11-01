# ============================================================
# ApplicationRecord
# ------------------------------------------------------------
# すべての ActiveRecord モデルの共通親クラス。
# ============================================================

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
