import Prelude
import ReactiveCocoa
import Result
import XCTest
@testable import KsApi
@testable import Library
@testable import ReactiveExtensions
@testable import ReactiveExtensions_TestHelpers

internal final class DiscoveryNavigationHeaderViewModelTests: TestCase {
  private let vm: DiscoveryNavigationHeaderViewModelType = DiscoveryNavigationHeaderViewModel()

  private let animateArrowToDown = TestObserver<Bool, NoError>()
  private let dividerIsHidden = TestObserver<Bool, NoError>()
  private let primaryLabelText = TestObserver<String, NoError>()
  private let notifyDelegateFilterSelectedParams = TestObserver<DiscoveryParams, NoError>()
  private let secondaryLabelText = TestObserver<String, NoError>()
  private let secondaryLabelIsHidden = TestObserver<Bool, NoError>()
  private let titleAccessibilityHint = TestObserver<String, NoError>()
  private let titleAccessibilityLabel = TestObserver<String, NoError>()
  private let showDiscoveryFiltersRow = TestObserver<SelectableRow, NoError>()
  private let showDiscoveryFiltersCats = TestObserver<[KsApi.Category], NoError>()
  private let favoriteButtonAccessibilityLabel = TestObserver<String, NoError>()
  private let favoriteViewIsDimmed = TestObserver<Bool, NoError>()
  private let favoriteViewIsHidden = TestObserver<Bool, NoError>()
  private let showFavoriteOnboardingAlert = TestObserver<String, NoError>()
  private let updateFavoriteButtonSelected = TestObserver<Bool, NoError>()
  private let updateFavoriteButtonAnimated = TestObserver<Bool, NoError>()

  let initialParams = .defaults
    |> DiscoveryParams.lens.staffPicks .~ true
    |> DiscoveryParams.lens.includePOTD .~ true

  let categoryParams = .defaults |> DiscoveryParams.lens.category .~ .art
  let subcategoryParams = .defaults |> DiscoveryParams.lens.category .~ .documentary
  let starredParams = .defaults |> DiscoveryParams.lens.starred .~ true

  let selectableRow = SelectableRow(isSelected: false, params: .defaults)

  internal override func setUp() {
    super.setUp()

    self.vm.outputs.animateArrowToDown.observe(self.animateArrowToDown.observer)
    self.vm.outputs.dividerIsHidden.observe(self.dividerIsHidden.observer)
    self.vm.outputs.primaryLabelText.observe(self.primaryLabelText.observer)
    self.vm.outputs.notifyDelegateFilterSelectedParams
      .observe(self.notifyDelegateFilterSelectedParams.observer)
    self.vm.outputs.secondaryLabelText.observe(self.secondaryLabelText.observer)
    self.vm.outputs.secondaryLabelIsHidden.observe(self.secondaryLabelIsHidden.observer)
    self.vm.outputs.titleButtonAccessibilityHint.observe(self.titleAccessibilityHint.observer)
    self.vm.outputs.titleButtonAccessibilityLabel.observe(self.titleAccessibilityLabel.observer)
    self.vm.outputs.showDiscoveryFilters.map(first).observe(self.showDiscoveryFiltersRow.observer)
    self.vm.outputs.showDiscoveryFilters.map(second).observe(self.showDiscoveryFiltersCats.observer)
    self.vm.outputs.favoriteButtonAccessibilityLabel.observe(self.favoriteButtonAccessibilityLabel.observer)
    self.vm.outputs.favoriteViewIsDimmed.observe(self.favoriteViewIsDimmed.observer)
    self.vm.outputs.favoriteViewIsHidden.observe(self.favoriteViewIsHidden.observer)
    self.vm.outputs.showFavoriteOnboardingAlert.observe(self.showFavoriteOnboardingAlert.observer)
    self.vm.outputs.updateFavoriteButton.map(first).observe(self.updateFavoriteButtonSelected.observer)
    self.vm.outputs.updateFavoriteButton.map(second).observe(self.updateFavoriteButtonAnimated.observer)
  }

  func testShowFilters() {
    let categories = [
      Category.illustration,
      .documentary,
      .filmAndVideo,
      .art
    ]

    let categoriesResponse = .template |> CategoriesEnvelope.lens.categories .~ categories
    let initialRow = SelectableRow(isSelected: true, params: initialParams)
    let starredRow = selectableRow |> SelectableRow.lens.params .~ starredParams
    let artRow = selectableRow |> SelectableRow.lens.params .~ categoryParams

    withEnvironment(apiService: MockService(fetchCategoriesResponse: categoriesResponse)) {

      self.vm.inputs.viewDidLoad()
      self.vm.inputs.configureWith(params: initialParams)

      self.showDiscoveryFiltersRow.assertValueCount(0)

      self.vm.inputs.titleButtonTapped()

      self.showDiscoveryFiltersRow.assertValues([initialRow])
      self.showDiscoveryFiltersCats.assertValues([categories])

      self.vm.inputs.filtersSelected(row: starredRow)

      self.showDiscoveryFiltersRow.assertValues([initialRow], "Show Filters does not emit on selection.")

      self.vm.inputs.titleButtonTapped()

      self.showDiscoveryFiltersRow.assertValues([initialRow, starredRow])
      self.showDiscoveryFiltersCats.assertValues([categories, categories])

      self.vm.inputs.titleButtonTapped()

      self.showDiscoveryFiltersRow.assertValues([initialRow, starredRow],
                                                "Show filters does not emit on close.")

      self.vm.inputs.titleButtonTapped()

      self.showDiscoveryFiltersRow.assertValues([initialRow, starredRow, starredRow])
      self.showDiscoveryFiltersCats.assertValues([categories, categories, categories])

      self.vm.inputs.filtersSelected(row: artRow)
      self.vm.inputs.titleButtonTapped()

      self.showDiscoveryFiltersRow.assertValues([initialRow, starredRow, starredRow, artRow])
      self.showDiscoveryFiltersCats.assertValues([categories, categories, categories, categories])
    }
  }

  func testTitleData() {
    self.vm.inputs.viewDidLoad()

    self.animateArrowToDown.assertValueCount(0)
    self.dividerIsHidden.assertValueCount(0)
    self.primaryLabelText.assertValueCount(0)
    self.secondaryLabelText.assertValueCount(0)
    self.secondaryLabelIsHidden.assertValueCount(0)
    self.titleAccessibilityHint.assertValueCount(0)
    self.titleAccessibilityLabel.assertValueCount(0)

    self.vm.inputs.configureWith(params: initialParams)

    self.animateArrowToDown.assertValues([true])
    self.dividerIsHidden.assertValues([true])
    self.primaryLabelText.assertValues([Strings.Projects_We_Love()])
    self.secondaryLabelText.assertValues([""])
    self.secondaryLabelIsHidden.assertValues([true])
    self.titleAccessibilityHint.assertValues([Strings.Opens_filters()])
    self.titleAccessibilityLabel.assertValues([Strings.Filter_by_projects_we_love()])

    self.vm.inputs.titleButtonTapped()

    self.animateArrowToDown.assertValues([true, false])
    self.dividerIsHidden.assertValues([true])
    self.primaryLabelText.assertValues([Strings.Projects_We_Love(), Strings.Projects_We_Love()])
    self.secondaryLabelText.assertValues(["", ""])
    self.secondaryLabelIsHidden.assertValues([true])
    self.titleAccessibilityHint.assertValues([Strings.Opens_filters(), Strings.Closes_filters()])
    self.titleAccessibilityLabel.assertValues([Strings.Filter_by_projects_we_love(),
      Strings.Filter_by_projects_we_love()])

    self.vm.inputs.filtersSelected(row: selectableRow |> SelectableRow.lens.params .~ starredParams)

    self.animateArrowToDown.assertValues([true, false, true])
    self.dividerIsHidden.assertValues([true])
    self.primaryLabelText.assertValues([Strings.Projects_We_Love(), Strings.Projects_We_Love(),
      Strings.discovery_saved()])
    self.secondaryLabelText.assertValues(["", "", ""])
    self.secondaryLabelIsHidden.assertValues([true])
    self.titleAccessibilityHint.assertValues([Strings.Opens_filters(), Strings.Closes_filters(),
      Strings.Opens_filters()])
    self.titleAccessibilityLabel.assertValues([Strings.Filter_by_projects_we_love(),
      Strings.Filter_by_projects_we_love(), Strings.Filter_by_starred_projects()])

    self.vm.inputs.titleButtonTapped()

    self.animateArrowToDown.assertValues([true, false, true, false])
    self.dividerIsHidden.assertValues([true])
    self.primaryLabelText.assertValues([Strings.Projects_We_Love(), Strings.Projects_We_Love(),
      Strings.discovery_saved(), Strings.discovery_saved()])
    self.secondaryLabelText.assertValues(["", "", "", ""])
    self.secondaryLabelIsHidden.assertValues([true])
    self.titleAccessibilityHint.assertValues([Strings.Opens_filters(), Strings.Closes_filters(),
      Strings.Opens_filters(), Strings.Closes_filters()])
    self.titleAccessibilityLabel.assertValues([Strings.Filter_by_projects_we_love(),
      Strings.Filter_by_projects_we_love(), Strings.Filter_by_starred_projects(),
      Strings.Filter_by_starred_projects()])

    self.vm.inputs.filtersSelected(row: selectableRow |> SelectableRow.lens.params .~ categoryParams)

    self.animateArrowToDown.assertValues([true, false, true, false, true])
    self.dividerIsHidden.assertValues([true])
    self.primaryLabelText.assertValues([Strings.Projects_We_Love(), Strings.Projects_We_Love(),
      Strings.discovery_saved(), Strings.discovery_saved(), Strings.All_Art_Projects()])
    self.secondaryLabelText.assertValues(["", "", "", "", ""])
    self.secondaryLabelIsHidden.assertValues([true])
    self.titleAccessibilityHint.assertValues([Strings.Opens_filters(), Strings.Closes_filters(),
      Strings.Opens_filters(), Strings.Closes_filters(), Strings.Opens_filters()])
    self.titleAccessibilityLabel.assertValues([Strings.Filter_by_projects_we_love(),
      Strings.Filter_by_projects_we_love(), Strings.Filter_by_starred_projects(),
      Strings.Filter_by_starred_projects(),
      Strings.Filter_by_category_name(category_name: categoryParams.category?.name ?? "")])

    self.vm.inputs.titleButtonTapped()

    self.animateArrowToDown.assertValues([true, false, true, false, true, false])
    self.dividerIsHidden.assertValues([true])
    self.primaryLabelText.assertValues([Strings.Projects_We_Love(), Strings.Projects_We_Love(),
      Strings.discovery_saved(), Strings.discovery_saved(), Strings.All_Art_Projects(),
      Strings.All_Art_Projects()])
    self.secondaryLabelText.assertValues(["", "", "", "", "", ""])
    self.secondaryLabelIsHidden.assertValues([true])
    self.titleAccessibilityHint.assertValues([Strings.Opens_filters(), Strings.Closes_filters(),
      Strings.Opens_filters(), Strings.Closes_filters(), Strings.Opens_filters(), Strings.Closes_filters()])
    self.titleAccessibilityLabel.assertValues([Strings.Filter_by_projects_we_love(),
      Strings.Filter_by_projects_we_love(), Strings.Filter_by_starred_projects(),
      Strings.Filter_by_starred_projects(),
      Strings.Filter_by_category_name(category_name: categoryParams.category?.name ?? ""),
      Strings.Filter_by_category_name(category_name: categoryParams.category?.name ?? "")
    ])

    self.vm.inputs.filtersSelected(row: selectableRow |> SelectableRow.lens.params .~ subcategoryParams)

    self.animateArrowToDown.assertValues([true, false, true, false, true, false, true])
    self.dividerIsHidden.assertValues([true, false])
    self.primaryLabelText.assertValues([Strings.Projects_We_Love(), Strings.Projects_We_Love(),
      Strings.discovery_saved(), Strings.discovery_saved(), Strings.All_Art_Projects(),
      Strings.All_Art_Projects(), "Film & Video"])
    self.secondaryLabelText.assertValues(["", "", "", "", "", "", "Documentary"])
    self.secondaryLabelIsHidden.assertValues([true, false])
    self.titleAccessibilityHint.assertValues([Strings.Opens_filters(), Strings.Closes_filters(),
      Strings.Opens_filters(), Strings.Closes_filters(), Strings.Opens_filters(), Strings.Closes_filters(),
      Strings.Opens_filters()])
    self.titleAccessibilityLabel.assertValues([Strings.Filter_by_projects_we_love(),
      Strings.Filter_by_projects_we_love(), Strings.Filter_by_starred_projects(),
      Strings.Filter_by_starred_projects(),
      Strings.Filter_by_category_name(category_name: categoryParams.category?.name ?? ""),
      Strings.Filter_by_category_name(category_name: categoryParams.category?.name ?? ""),
      Strings.Filter_by_subcategory_name_in_category_name(
        subcategory_name: subcategoryParams.category?.name ?? "",
        category_name: subcategoryParams.category?.root?.name ?? "")
      ])
  }

  func testNotifyFilterSelectedParams() {
    self.vm.inputs.viewDidLoad()
    self.vm.inputs.configureWith(params: initialParams)

    self.notifyDelegateFilterSelectedParams.assertValueCount(0)

    self.vm.inputs.filtersSelected(row: selectableRow)

    self.notifyDelegateFilterSelectedParams.assertValues([DiscoveryParams.defaults])

    self.vm.inputs.filtersSelected(row: selectableRow |> SelectableRow.lens.params .~ categoryParams)

    self.notifyDelegateFilterSelectedParams.assertValues([DiscoveryParams.defaults, categoryParams])
  }

  func testFavoriting() {
    let artSelectableRow = selectableRow |> SelectableRow.lens.params .~ categoryParams

    self.vm.inputs.viewDidLoad()
    self.vm.inputs.configureWith(params: initialParams)

    self.favoriteViewIsHidden.assertValues([true])

    self.vm.inputs.titleButtonTapped()

    self.favoriteViewIsHidden.assertValues([true])
    self.favoriteViewIsDimmed.assertValueCount(0)
    self.updateFavoriteButtonAnimated.assertValueCount(0)
    self.updateFavoriteButtonSelected.assertValueCount(0)
    self.favoriteButtonAccessibilityLabel.assertValueCount(0)

    self.vm.inputs.filtersSelected(row: artSelectableRow)

    self.favoriteViewIsHidden.assertValues([true, false])
    self.favoriteViewIsDimmed.assertValues([false])
    self.updateFavoriteButtonAnimated.assertValues([false])
    self.updateFavoriteButtonSelected.assertValues([false])
    self.showFavoriteOnboardingAlert.assertValueCount(0)
    self.favoriteButtonAccessibilityLabel.assertValues([
      Strings.discovery_favorite_categories_buttons_favorite_a11y_label()
    ])

    self.vm.inputs.favoriteButtonTapped()

    self.favoriteViewIsHidden.assertValues([true, false])
    self.favoriteViewIsDimmed.assertValues([false])
    self.updateFavoriteButtonAnimated.assertValues([false, true])
    self.updateFavoriteButtonSelected.assertValues([false, true])
    self.showFavoriteOnboardingAlert.assertValues(["All Art Projects"])
    self.favoriteButtonAccessibilityLabel.assertValues([
      Strings.discovery_favorite_categories_buttons_favorite_a11y_label(),
      Strings.discovery_favorite_categories_buttons_unfavorite_a11y_label()
      ])

    self.vm.inputs.titleButtonTapped()

    self.favoriteViewIsHidden.assertValues([true, false])
    self.favoriteViewIsDimmed.assertValues([false, true])
    self.updateFavoriteButtonAnimated.assertValues([false, true])
    self.updateFavoriteButtonSelected.assertValues([false, true])
    self.showFavoriteOnboardingAlert.assertValues(["All Art Projects"])
    self.favoriteButtonAccessibilityLabel.assertValues([
      Strings.discovery_favorite_categories_buttons_favorite_a11y_label(),
      Strings.discovery_favorite_categories_buttons_unfavorite_a11y_label()
      ])

    self.vm.inputs.titleButtonTapped()

    self.favoriteViewIsHidden.assertValues([true, false])
    self.favoriteViewIsDimmed.assertValues([false, true, false])
    self.updateFavoriteButtonAnimated.assertValues([false, true])
    self.updateFavoriteButtonSelected.assertValues([false, true])
    self.showFavoriteOnboardingAlert.assertValues(["All Art Projects"])
    self.favoriteButtonAccessibilityLabel.assertValues([
      Strings.discovery_favorite_categories_buttons_favorite_a11y_label(),
      Strings.discovery_favorite_categories_buttons_unfavorite_a11y_label()
      ])

    self.vm.inputs.favoriteButtonTapped()

    self.favoriteViewIsHidden.assertValues([true, false])
    self.favoriteViewIsDimmed.assertValues([false, true, false])
    self.updateFavoriteButtonAnimated.assertValues([false, true, true])
    self.updateFavoriteButtonSelected.assertValues([false, true, false])
    self.showFavoriteOnboardingAlert.assertValues(["All Art Projects"], "Alert does not emit again.")
    self.favoriteButtonAccessibilityLabel.assertValues([
      Strings.discovery_favorite_categories_buttons_favorite_a11y_label(),
      Strings.discovery_favorite_categories_buttons_unfavorite_a11y_label(),
      Strings.discovery_favorite_categories_buttons_favorite_a11y_label()
    ])

    self.vm.inputs.titleButtonTapped()

    self.favoriteViewIsHidden.assertValues([true, false])
    self.favoriteViewIsDimmed.assertValues([false, true, false, true])
    self.updateFavoriteButtonAnimated.assertValues([false, true, true])
    self.updateFavoriteButtonSelected.assertValues([false, true, false])
    self.showFavoriteOnboardingAlert.assertValues(["All Art Projects"], "Alert does not emit again.")
    self.favoriteButtonAccessibilityLabel.assertValues([
      Strings.discovery_favorite_categories_buttons_favorite_a11y_label(),
      Strings.discovery_favorite_categories_buttons_unfavorite_a11y_label(),
      Strings.discovery_favorite_categories_buttons_favorite_a11y_label()
      ])

    self.vm.inputs.filtersSelected(row: selectableRow)

    self.favoriteViewIsHidden.assertValues([true, false, true])
    self.favoriteViewIsDimmed.assertValues([false, true, false, true])
    self.updateFavoriteButtonAnimated.assertValues([false, true, true])
    self.updateFavoriteButtonSelected.assertValues([false, true, false])
    self.showFavoriteOnboardingAlert.assertValues(["All Art Projects"], "Alert does not emit again.")
    self.favoriteButtonAccessibilityLabel.assertValues([
      Strings.discovery_favorite_categories_buttons_favorite_a11y_label(),
      Strings.discovery_favorite_categories_buttons_unfavorite_a11y_label(),
      Strings.discovery_favorite_categories_buttons_favorite_a11y_label()
      ])
  }

  func testCloseFiltersTracking() {
    self.vm.inputs.viewDidLoad()
    self.vm.inputs.configureWith(params: initialParams)

    self.vm.inputs.titleButtonTapped()

    self.vm.inputs.filtersSelected(row: selectableRow)

    self.vm.inputs.titleButtonTapped()

    XCTAssertEqual([], self.trackingClient.events)

    self.vm.inputs.titleButtonTapped()

    XCTAssertEqual(["Closed Discovery Filter"], self.trackingClient.events)

    self.vm.inputs.titleButtonTapped()

    self.vm.inputs.filtersSelected(row: selectableRow)

    self.vm.inputs.titleButtonTapped()

    XCTAssertEqual(["Closed Discovery Filter"], self.trackingClient.events, "Closed event does not emit")

    self.vm.inputs.titleButtonTapped()

    XCTAssertEqual(["Closed Discovery Filter", "Closed Discovery Filter"], self.trackingClient.events)
  }
}
