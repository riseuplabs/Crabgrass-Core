require File.dirname(__FILE__) + '/test_helper'

class I18nTest < ActiveSupport::TestCase

  def setup
    I18n.backend = I18n::Backend::Simple.new
    #I18n.backend.stubs(:initialized?).returns(true)
    I18n.locale = :en

    I18n.backend.store_translations(:en, {
      :test_title => "Hello %{what}",
      :test_name => "default %{what}",
      :say_hi => "OH HAI",
      :say_oh_my_gosh => "only here",
      :scope => { :me => 'scope off site' },
      :thediggers => {
        :test_title => "%{what} come to dig and sow.",
        :say_hi => "hi diggers",
        :scope => { :me => 'scope on site' },
      },
      :custom => {
       :test_title => "Custom Hello %{what}",
       :say_hi => "custom hi!"}
    })
    I18n.backend.store_translations(:bw, {
      :test_title => "Olleh %{what}",
      :test_name => "tluafed %{what}",
      :thediggers => {
        :test_title => "wos dna gid ot emoc %{what}"},
      :custom => {
        :test_title => "%{what} olleH motsuC"}
    })

    @site = Site.create(:name => "thediggers")
  end

  def teardown
    I18n.backend = nil
    I18n.locale = :en
  end

  #def add_translation(locale, dictionary)
  #  I18n.backend.send(:merge_translations, locale, dictionary)
  #end


  def test_site_specific_translation_scope_is_added
    with_site("thediggers") do
      assert_equal "We come to dig and sow.", I18n.translate(:test_title, :what => "We"), "Site specific translation should come up when Site.current is set"
      assert_equal "We come to dig and sow.", I18n.t(:test_title, :what => "We"), "Site specific translation should come up when Site.current is set"

      I18n.locale = :bw
      assert_equal "wos dna gid ot emoc We", I18n.translate(:test_title, :what => "We"), "Site specific translation should come up for a different language"
      assert_equal "wos dna gid ot emoc We", I18n.t(:test_title, :what => "We"), "Site specific translation should come up for a different language"
    end
  end

  def test_without_site_language_translations_are_used
    assert_equal "Hello World", I18n.t(:test_title, :what => "World"), "Default language translations should be available"
    assert_equal "Hello World", I18n.translate(:test_title, :what => "World"), "Default language translations should be available"

    I18n.locale = :bw
    assert_equal "Olleh World", I18n.t(:test_title, :what => "World"), "Default language translations should be available"
    assert_equal "Olleh World", I18n.translate(:test_title, :what => "World"), "Default language translations should be available"
  end

  def test_fallbacks_in_order_of_precendence
    with_site("thediggers") do
      I18n.locale = :bw
      assert_equal "tluafed name",
        I18n.t(:test_name, :what => "name", :default => "don't use the default"),
        "should fall-back to the right language translations"
      assert_equal "the default",
        I18n.t(:say_hi, :default => "the default"),
        "should fallback to default given if no translation is available"
      assert_equal "hi diggers",
        I18n.t(:say_hi),
        "should fallback to site-specific english translation if no default is given"
      assert_equal "only here",
        I18n.t(:say_oh_my_gosh),
        "should fallback to english locale if nothing more specific is present"
    end
  end

  def test_site_version_of_scoped_translation_works
    with_site("thediggers") do
      assert_equal "scope on site", I18n.translate(:me, :scope => :scope), "Translate scoped key specifically for the site"
    end
  end

  def test_non_site_version_of_scoped_translation_works
    assert_equal "scope off site", I18n.translate(:me, :scope => :scope), "Translate scoped key off the site"
  end

  #def test_custom_translations_without_site
  #def test_custom_translations_without_site
  #def test_custom_translations_without_site
  #def test_custom_translations_without_site
  #  Site.stubs(:current).returns(Site.new(:name => 'custom'))
  #  add_translation(:en, {
  #                         :custom => {
  #                             :test_title => "Custom Hello {{what}}",
  #                             :say_hi => "custom hi!"}})
  #  assert_equal "custom hi!", I18n.t(:say_hi), "Translated string should be custom translation."
  #end

end
