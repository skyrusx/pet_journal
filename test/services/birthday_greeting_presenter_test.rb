require "test_helper"

class BirthdayGreetingPresenterTest < ActiveSupport::TestCase
  test "single pet uses approved copy and correct age plural" do
    pet = pets(:one)
    pet.assign_attributes(name: "Тор", sex: 0, birth_date: Date.new(2018, 9, 2))
    presenter = BirthdayGreetingPresenter.new(pets: [pet], date: Date.new(2026, 9, 2))

    assert_equal "🎉 Сегодня день рождения Тора!", presenter.title
    assert_equal "Исполняется 8 лет. Самое время обнять именинника чуть крепче и угостить вкусняшкой 🐾", presenter.body
  end

  test "two pets use combined approved copy" do
    tor = pets(:one).dup
    tor.assign_attributes(name: "Тор", sex: 0)
    loki = pets(:two).dup
    loki.assign_attributes(name: "Локи", sex: 0)
    presenter = BirthdayGreetingPresenter.new(pets: [tor, loki], date: Date.new(2026, 9, 2))

    assert_equal "🎉 Сегодня день рождения у Тора и Локи!", presenter.title
    assert_equal "Настоящий двойной праздник. Самое время обнять именинников чуть крепче и угостить вкусняшками 🐾", presenter.body
  end

  test "three pets keep names in nominative in body" do
    tor = pets(:one).dup
    tor.assign_attributes(name: "Тор", sex: 0)
    loki = pets(:two).dup
    loki.assign_attributes(name: "Локи", sex: 0)
    freya = pets(:one).dup
    freya.assign_attributes(name: "Фрея", sex: 1)
    presenter = BirthdayGreetingPresenter.new(pets: [tor, loki, freya], date: Date.new(2026, 9, 2))

    assert_equal "🎉 Сегодня настоящий праздник!", presenter.title
    assert_equal "День рождения отмечают Тор, Локи и Фрея. Самое время обнять именинников чуть крепче и угостить вкусняшками 🐾", presenter.body
  end

  test "more than three pets uses overflow avatar" do
    pets_list = 4.times.map do |index|
      pet = pets(:one).dup
      pet.name = "Питомец #{index + 1}"
      pet
    end
    presenter = BirthdayGreetingPresenter.new(pets: pets_list, date: Date.new(2026, 9, 2))

    assert_equal 2, presenter.avatar_pets.size
    assert_equal 2, presenter.overflow_count
  end
end
