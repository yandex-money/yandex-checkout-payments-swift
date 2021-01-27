import UIKit.UIViewController

/// Tokenization module builder.
public enum TokenizationAssembly {

    /// Creates tokenization view controller.
    ///
    /// - Returns: Tokenization view controller which implements the protocol `TokenizationModuleInput`.
    public static func makeModule(
        inputData: TokenizationFlow,
        moduleOutput: TokenizationModuleOutput
    ) -> UIViewController & TokenizationModuleInput {
        switch inputData {
        case .tokenization(let tokenizationModuleInputData):
            return makeTokenizationModule(tokenizationModuleInputData, moduleOutput: moduleOutput)

        case .bankCardRepeat(let bankCardRepeatModuleInputData):
            return makeBankCardRepeatModule(bankCardRepeatModuleInputData, moduleOutput: moduleOutput)
        }
    }

    private static func makeBankCardRepeatModule(
        _ inputData: BankCardRepeatModuleInputData,
        moduleOutput: TokenizationModuleOutput
    ) -> UIViewController & TokenizationModuleInput {
        let view = TokenizationViewController()

        let paymentMethodViewModelFactory = PaymentMethodViewModelFactoryAssembly.makeFactory()
        let presenter = BankCardRepeatPresenter(
            inputData: inputData,
            paymentMethodViewModelFactory: paymentMethodViewModelFactory
        )

        let paymentService = PaymentServiceAssembly.makeService(
            tokenizationSettings: TokenizationSettings(),
            testModeSettings: inputData.testModeSettings,
            isLoggingEnabled: inputData.isLoggingEnabled
        )

        let analyticsService = AnalyticsServiceAssembly.makeService(
            isLoggingEnabled: inputData.isLoggingEnabled
        )

        let interactor = BankCardRepeatInteractor(
            clientApplicationKey: inputData.clientApplicationKey,
            paymentService: paymentService,
            analyticsService: analyticsService
        )
        let router = TokenizationRouter()

        view.output = presenter
        view.modalPresentationStyle = .custom

        presenter.view = view
        presenter.moduleOutput = moduleOutput
        presenter.interactor = interactor
        presenter.router = router

        interactor.output = presenter

        router.transitionHandler = view

        return view
    }

    private static func makeTokenizationModule(
        _ inputData: TokenizationModuleInputData,
        moduleOutput: TokenizationModuleOutput
    ) -> UIViewController & TokenizationModuleInput {
        let paymentService = PaymentServiceAssembly.makeService(
            tokenizationSettings: inputData.tokenizationSettings,
            testModeSettings: inputData.testModeSettings,
            isLoggingEnabled: inputData.isLoggingEnabled
        )
        let authorizationService = AuthorizationServiceAssembly.makeService(
            isLoggingEnabled: inputData.isLoggingEnabled,
            testModeSettings: inputData.testModeSettings,
            moneyAuthClientId: inputData.moneyAuthClientId
        )
        let analyticsService = AnalyticsServiceAssembly.makeService(
            isLoggingEnabled: inputData.isLoggingEnabled
        )
        let analyticsProvider = AnalyticsProviderAssembly.makeProvider(
            testModeSettings: inputData.testModeSettings
        )

        let viewController = TokenizationViewController()

        let paymentMethodViewModelFactory = PaymentMethodViewModelFactoryAssembly.makeFactory()
        let presenter = TokenizationPresenter(
            inputData: inputData,
            paymentMethodViewModelFactory: paymentMethodViewModelFactory
        )
        let router = TokenizationRouter()
        let interactor = TokenizationInteractor(
            paymentService: paymentService,
            authorizationService: authorizationService,
            analyticsService: analyticsService,
            analyticsProvider: analyticsProvider,
            clientApplicationKey: inputData.clientApplicationKey
        )

        viewController.output = presenter

        presenter.router = router
        presenter.interactor = interactor
        presenter.moduleOutput = moduleOutput
        presenter.view = viewController

        interactor.output = presenter

        router.transitionHandler = viewController

        let navigationController = UINavigationController(
            rootViewController: viewController
        )

        return navigationController
    }
}

// TODO: Fix it in https://jira.yamoney.ru/browse/MOC-1563
extension UINavigationController: TokenizationModuleInput {
    public func start3dsProcess(requestUrl: String) {}
}
