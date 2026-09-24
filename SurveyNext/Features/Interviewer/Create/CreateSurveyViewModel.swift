import Foundation
import Observation

/// Equivalent of `CreateSurveyViewModel`.
@Observable
final class CreateSurveyViewModel {
    private(set) var options: LoadState<CreateSurveyForm> = .loading

    var title = "" { didSet { titleError = nil } }
    var description = "" { didSet { descriptionError = nil } }
    var minutes = 5
    var category: Category? = nil { didSet { categoryError = nil } }
    var region: Region? = nil { didSet { regionError = nil } }

    /// Set through `selectCountry`, which also loads its regions.
    private(set) var country: Country? = nil
    private(set) var regions: [Region] = []
    private(set) var regionsLoading = false

    private(set) var titleError: String?
    private(set) var descriptionError: String?
    private(set) var categoryError: String?
    private(set) var countryError: String?
    private(set) var regionError: String?

    private(set) var isSubmitting = false
    var errorMessage: String?

    @ObservationIgnored private let repository: any InterviewerRepository
    @ObservationIgnored private let session: SessionStore

    init(repository: any InterviewerRepository, session: SessionStore) {
        self.repository = repository
        self.session = session
    }

    func load() async {
        options = .loading
        do {
            let form = try await repository.createSurveyForm()
            options = .loaded(form)
            // Default to targeting the author's own country and region.
            if let user = session.user, let home = form.countryList.first(where: { $0.id == user.countryId }) {
                await selectCountry(home, preferredRegionId: user.regionId)
            }
        } catch is CancellationError {
        } catch {
            options = .failed(error.localizedDescription)
        }
    }

    func selectCountry(_ country: Country, preferredRegionId: Int? = nil) async {
        guard country != self.country || preferredRegionId != nil else { return }
        self.country = country
        region = nil
        regions = []
        regionsLoading = true
        countryError = nil
        do {
            let loaded = try await repository.regions(countryId: country.id)
            // Ignore the answer if another country was picked meanwhile.
            guard self.country == country else { return }
            regions = loaded
            region = loaded.first { $0.id == preferredRegionId }
        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }
        if self.country == country {
            regionsLoading = false
        }
    }

    /// Creates the draft and returns its id, or nil when something's missing.
    func submit() async -> Int? {
        titleError = title.trimmed.isEmpty ? "Give your survey a title" : nil
        descriptionError = description.trimmed.isEmpty ? "Tell respondents what it's about" : nil
        categoryError = category == nil ? "Pick a category" : nil
        countryError = country == nil ? "Pick a country" : nil
        regionError = region == nil ? "Pick a region" : nil

        guard titleError == nil, descriptionError == nil,
              let category, let country, let region, !isSubmitting else { return nil }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let survey = try await repository.createSurvey(CreateSurveyRequest(
                title: title.trimmed,
                description: description.trimmed,
                categoryId: category.id,
                countryId: country.id,
                regionId: region.id,
                minutes: minutes
            ))
            return survey.id
        } catch is CancellationError {
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
