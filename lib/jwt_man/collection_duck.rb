# frozen_string_literal: true

module JwtMan
  ##
  # A Duck for ActiveRecord::Collection collection allowing to call destroy on each element. Used in JwtMan::JtiList
  class CollectionDuck < Array
    def destroy_all
      each(&:destroy)
    end
    alias destroy_all! destroy_all
    alias delete_all destroy_all
  end
end
