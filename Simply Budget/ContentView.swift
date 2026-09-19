import SwiftUI

// MARK: - Brand Colors
// This section creates custom colors that we can reuse throughout the app.
// Instead of typing the RGB values every time, we can write Color.simplyGreen.

extension Color {
    static let simplyGreen = Color(red: 32 / 255, green: 167 / 255, blue: 122 / 255)
    static let simplyDarkGreen = Color(red: 22 / 255, green: 125 / 255, blue: 92 / 255)
    static let simplyLightGreen = Color(red: 234 / 255, green: 247 / 255, blue: 242 / 255)
    static let simplyVeryLightGreen = Color(red: 246 / 255, green: 251 / 255, blue: 249 / 255)
    static let simplyRed = Color(red: 217 / 255, green: 74 / 255, blue: 74 / 255)
    static let simplyDarkCard = Color(red: 31 / 255, green: 39 / 255, blue: 37 / 255)
    static let simplyDarkIncomeCard = Color(red: 27 / 255, green: 35 / 255, blue: 33 / 255)
}


// MARK: - Transaction Category

// An enum is useful when something should only have certain choices.
// A transaction category can only be one of the choices below.
//
// Codable lets Swift save/load this value.
// CaseIterable lets us loop through every category.
// Identifiable helps SwiftUI tell each category apart.

enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
    case transportation = "Transportation"
    case gas = "Gas"
    case groceries = "Groceries"
    case toiletries = "Toiletries"
    case rent = "Rent"
    case debt = "Debt"
    case subscriptions = "Subscriptions"
    case clothes = "Clothes"
    case savings = "Savings"
    case other = "Other"

    var id: String {
        rawValue
    }

    // This is a computed property.
    // It returns the SF Symbol that belongs to each category.
    var icon: String {
        switch self {
        case .transportation:
            return "car.fill"
        case .gas:
            return "fuelpump.fill"
        case .groceries:
            return "cart.fill"
        case .toiletries:
            return "basket.fill"
        case .rent:
            return "house.fill"
        case .debt:
            return "creditcard.fill"
        case .subscriptions:
            return "repeat"
        case .clothes:
            return "tshirt.fill"
        case .savings:
            return "banknote.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
}


// MARK: - Transaction Model

// A struct lets us create our own type.
//
// This struct describes what ONE transaction looks like.
// Every transaction in the app has these six pieces of information.

struct Transaction: Identifiable, Codable {

    // UUID gives every transaction its own unique ID.
    // This is how Swift can tell two transactions apart.
    var id: UUID = UUID()

    // Example: "Gas" or "Honda Car Payment"
    var name: String

    // Example: 75.00
    var amount: Double

    // The date the transaction happens.
    var date: Date

    // true = money coming in
    // false = money going out
    var isDeposit: Bool

    // The expense category.
    var category: TransactionCategory
}


// MARK: - Main View

// ContentView is the main screen of our app.
//
// ": View" tells Swift that ContentView is something
// SwiftUI should be able to display on the screen.

struct ContentView: View {

    // Environment lets us read information from iOS.
    // Here we are checking whether the phone is using Light Mode or Dark Mode.
    @Environment(\.colorScheme) private var colorScheme

    // @State means this value can change while the app is running.
    // When State changes, SwiftUI can automatically redraw the screen.

    @State private var currentBalance: Double = 0

    // This array stores all of our Transaction objects.
    @State private var transactions: [Transaction] = []

    @State private var showingBalanceEditor = false
    @State private var showingTransactionEditor = false

    // The ? means this value is optional.
    // It can contain a Transaction OR contain nothing (nil).
    @State private var editingTransaction: Transaction?

    @State private var selectedCategory: TransactionCategory = .other
    @State private var addingDeposit = false

    // NEW:
    // selectedMonth controls which month the user is currently looking at.
    //
    // Date() means "right now."
    // Therefore, whenever the app starts, it begins on the current month.
    @State private var selectedMonth = Date()

    // These are the names used when saving our data to UserDefaults.
    private let transactionsKey = "savedTransactions"
    private let balanceKey = "savedCurrentBalance"


    // MARK: - Colors

    // These computed properties return different colors
    // depending on whether the phone is in Light Mode or Dark Mode.

    private var balanceCardBackground: Color {
        colorScheme == .dark
            ? Color.simplyDarkCard
            : Color.simplyLightGreen
    }

    private var incomeCardBackground: Color {
        colorScheme == .dark
            ? Color.simplyDarkIncomeCard
            : Color.simplyVeryLightGreen
    }


    // MARK: - Month Logic

    // Calendar gives us tools for working with dates.
    private var calendar: Calendar {
        Calendar.current
    }

    // This turns selectedMonth into text such as:
    //
    // September 2026
    //
    // This is what we show between the left and right arrows.
    private var selectedMonthTitle: String {
        selectedMonth.formatted(
            .dateTime
                .month(.wide)
                .year()
        )
    }

    // This function checks whether a date belongs
    // to the month the user is currently viewing.
    //
    // It returns a Bool:
    // true = yes
    // false = no
    private func isInSelectedMonth(_ date: Date) -> Bool {
        calendar.isDate(
            date,
            equalTo: selectedMonth,
            toGranularity: .month
        )
    }

    // Move backward one month.
    private func previousMonth() {
        if let newMonth = calendar.date(
            byAdding: .month,
            value: -1,
            to: selectedMonth
        ) {
            selectedMonth = newMonth
        }
    }

    // Move forward one month.
    private func nextMonth() {
        if let newMonth = calendar.date(
            byAdding: .month,
            value: 1,
            to: selectedMonth
        ) {
            selectedMonth = newMonth
        }
    }

    // When creating a transaction, we need a useful default date.
    //
    // If the user is looking at the CURRENT month,
    // we use today's actual date.
    //
    // If the user is looking at another month,
    // we use the first day of that month.
    private var defaultTransactionDate: Date {
        if calendar.isDate(
            selectedMonth,
            equalTo: Date(),
            toGranularity: .month
        ) {
            return Date()
        }

        let components = calendar.dateComponents(
            [.year, .month],
            from: selectedMonth
        )

        return calendar.date(from: components) ?? selectedMonth
    }


    // MARK: - Monthly Deposits

    // This is a computed property.
    //
    // It starts with ALL transactions.
    //
    // filter keeps only:
    // 1. deposits
    // 2. transactions inside the selected month
    //
    // sorted then puts them in date order.

    var deposits: [Transaction] {
        transactions
            .filter { transaction in
                transaction.isDeposit &&
                isInSelectedMonth(transaction.date)
            }
            .sorted { firstTransaction, secondTransaction in
                firstTransaction.date < secondTransaction.date
            }
    }


    // MARK: - Monthly Expenses

    // This function finds expenses for ONE category.
    //
    // For example:
    // expenses(for: .gas)
    //
    // would return only Gas expenses from the selected month.

    func expenses(for category: TransactionCategory) -> [Transaction] {
        transactions
            .filter { transaction in
                !transaction.isDeposit &&
                transaction.category == category &&
                isInSelectedMonth(transaction.date)
            }
            .sorted { firstTransaction, secondTransaction in
                firstTransaction.date < secondTransaction.date
            }
    }

    // Add together all expenses inside one category.
    func categoryTotal(_ category: TransactionCategory) -> Double {
        expenses(for: category)
            .reduce(0) { runningTotal, transaction in
                runningTotal + transaction.amount
            }
    }


    // MARK: - Monthly Totals

    // reduce is used to turn several values into one value.
    //
    // Here we start at 0 and add each deposit amount.

    var totalDeposits: Double {
        deposits.reduce(0) { runningTotal, transaction in
            runningTotal + transaction.amount
        }
    }

    // We only total expenses that belong to the selected month.
    var totalExpenses: Double {
        transactions
            .filter { transaction in
                !transaction.isDeposit &&
                isInSelectedMonth(transaction.date)
            }
            .reduce(0) { runningTotal, transaction in
                runningTotal + transaction.amount
            }
    }

    // This is our current simple balance calculation.
    //
    // Current Balance
    // + Deposits
    // - Expenses
    //
    // We are intentionally keeping the existing balance system
    // instead of creating separate starting balances for every month.
    var projectedBalance: Double {
        currentBalance + totalDeposits - totalExpenses
    }


    // MARK: - Transaction Name History

    // This creates a list of previously used transaction names.
    //
    // We pass this list into the transaction editor so it can
    // suggest names while the user types.
    //
    // Example:
    // Gas
    // Groceries
    // Costco
    // Honda Car Payment

    private var previousTransactionNames: [String] {

        // Set automatically removes duplicate values.
        let uniqueNames = Set(
            transactions.map { transaction in
                transaction.name
            }
        )

        // Turn the Set back into an Array and alphabetize it.
        return uniqueNames.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }


    // MARK: - Screen

    var body: some View {

        NavigationStack {

            List {

                // MARK: Branding

                Section {

                    HStack(spacing: 12) {

                        Image("SimplyBudgetLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 46, height: 46)

                        VStack(alignment: .leading, spacing: 2) {

                            Text("Simply Budget")
                                .font(
                                    .system(
                                        size: 22,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(.primary)

                            Text("Budgeting made simple.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 2)
                }


                // MARK: Month Selector

                Section {

                    HStack {

                        // Go back one month.
                        Button {
                            previousMonth()
                        } label: {
                            Image(systemName: "chevron.left")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.simplyGreen)
                                .frame(width: 44, height: 36)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        VStack(spacing: 2) {

                            Text(selectedMonthTitle)
                                .font(
                                    .system(
                                        size: 18,
                                        weight: .semibold,
                                        design: .rounded
                                    )
                                )

                            // If the selected month is the current month,
                            // we give the user a small visual reminder.
                            if calendar.isDate(
                                selectedMonth,
                                equalTo: Date(),
                                toGranularity: .month
                            ) {
                                Text("Current Month")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        // Go forward one month.
                        Button {
                            nextMonth()
                        } label: {
                            Image(systemName: "chevron.right")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.simplyGreen)
                                .frame(width: 44, height: 36)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }


                // MARK: Current Balance

                Section {

                    VStack(alignment: .leading, spacing: 7) {

                        HStack {

                            Text("Current Balance")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Image(systemName: "wallet.bifold.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.simplyGreen)
                        }

                        Text(
                            currentBalance,
                            format: .currency(code: "USD")
                        )
                        .font(
                            .system(
                                size: 31,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.primary)

                        Button {
                            showingBalanceEditor = true
                        } label: {

                            Label(
                                "Update Balance",
                                systemImage: "pencil"
                            )
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.simplyGreen)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(balanceCardBackground)


                // MARK: Income / Deposits

                Section {

                    HStack {

                        Label {
                            Text("Income / Deposits")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundStyle(Color.simplyGreen)
                        }

                        Spacer()

                        SubtleAddButton {
                            addDeposit()
                        }
                    }

                    if deposits.isEmpty {

                        Text("No deposits added")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                    } else {

                        // ForEach repeats this piece of UI
                        // once for every deposit.
                        ForEach(deposits) { transaction in

                            TransactionRow(
                                transaction: transaction
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editTransaction(transaction)
                            }
                        }
                    }

                    if totalDeposits > 0 {

                        HStack {

                            Text("Total Deposits")
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(
                                totalDeposits,
                                format: .currency(code: "USD")
                            )
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.simplyGreen)
                        }
                    }
                }
                .listRowBackground(incomeCardBackground)


                // MARK: Expenses

                Section {

                    // CaseIterable allows us to loop through
                    // every TransactionCategory.
                    ForEach(TransactionCategory.allCases) { category in

                        CategoryView(
                            category: category,
                            transactions: expenses(for: category),
                            total: categoryTotal(category),
                            onAdd: {
                                addExpense(category: category)
                            },
                            onEdit: { transaction in
                                editTransaction(transaction)
                            }
                        )
                    }

                } header: {

                    Text("Expenses")
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.primary)
                        .textCase(nil)
                        .padding(.top, 4)
                }


                // MARK: Summary

                Section {

                    HStack {

                        Text("Total Expenses")
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(
                            totalExpenses,
                            format: .currency(code: "USD")
                        )
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.simplyRed)
                    }

                    VStack(alignment: .leading, spacing: 6) {

                        Text("Balance After Expenses")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(
                            projectedBalance,
                            format: .currency(code: "USD")
                        )
                        .font(
                            .system(
                                size: 30,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(
                            projectedBalance < 0
                                ? Color.simplyRed
                                : Color.simplyGreen
                        )
                    }
                    .padding(.vertical, 4)

                } header: {

                    Text("Summary")
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)

            // We hide the normal navigation bar because
            // our design already contains its own branding.
            .toolbar(.hidden, for: .navigationBar)

            .tint(Color.simplyGreen)


            // MARK: Balance Editor Sheet

            // .sheet presents another screen over this one.
            .sheet(
                isPresented: $showingBalanceEditor
            ) {

                BalanceEditorView(
                    currentBalance: $currentBalance
                ) {
                    saveBalance()
                }
                .tint(Color.simplyGreen)
            }


            // MARK: Transaction Editor Sheet

            .sheet(
                isPresented: $showingTransactionEditor
            ) {

                TransactionEditorView(
                    transaction: editingTransaction,
                    category: selectedCategory,
                    startingAsDeposit: addingDeposit,

                    // NEW:
                    // Give the editor our previous transaction names.
                    previousNames: previousTransactionNames,

                    // NEW:
                    // Give the editor the correct default date.
                    defaultDate: defaultTransactionDate

                ) { savedTransaction in

                    saveTransaction(savedTransaction)
                }
                .tint(Color.simplyGreen)
            }


            // MARK: Load Saved Data

            // onAppear runs when this screen appears.
            .onAppear {
                loadData()
            }
        }
    }


    // MARK: - Add Deposit

    private func addDeposit() {

        // nil means we are NOT editing an old transaction.
        // We are creating a new one.
        editingTransaction = nil

        selectedCategory = .other
        addingDeposit = true
        showingTransactionEditor = true
    }


    // MARK: - Add Expense

    private func addExpense(
        category: TransactionCategory
    ) {

        editingTransaction = nil
        selectedCategory = category
        addingDeposit = false
        showingTransactionEditor = true
    }


    // MARK: - Edit Transaction

    private func editTransaction(
        _ transaction: Transaction
    ) {

        // Store the transaction the user tapped.
        editingTransaction = transaction

        selectedCategory = transaction.category
        addingDeposit = transaction.isDeposit
        showingTransactionEditor = true
    }


    // MARK: - Save Transaction

    private func saveTransaction(
        _ transaction: Transaction
    ) {

        // firstIndex searches our transaction array for
        // another transaction with the same unique ID.
        //
        // If we find one, the user was EDITING.
        // If we don't find one, the user was ADDING.

        if let index = transactions.firstIndex(
            where: {
                $0.id == transaction.id
            }
        ) {

            // Replace the old transaction.
            transactions[index] = transaction

        } else {

            // Add a brand-new transaction.
            transactions.append(transaction)
        }

        saveTransactions()
    }


    // MARK: - Persistence

    // Persistence means keeping data even after
    // the app closes.

    private func saveTransactions() {

        do {

            // JSONEncoder converts our Swift Transaction array
            // into data that can be saved.
            let data = try JSONEncoder()
                .encode(transactions)

            UserDefaults.standard.set(
                data,
                forKey: transactionsKey
            )

        } catch {

            print(
                "Transaction save error:",
                error
            )
        }
    }

    private func saveBalance() {

        UserDefaults.standard.set(
            currentBalance,
            forKey: balanceKey
        )
    }

    private func loadData() {

        // Load the saved balance.
        currentBalance =
            UserDefaults.standard.double(
                forKey: balanceKey
            )

        // Try to find previously saved transaction data.
        guard
            let data = UserDefaults.standard.data(
                forKey: transactionsKey
            )
        else {
            return
        }

        do {

            // JSONDecoder does the opposite of JSONEncoder.
            // It turns saved data back into Swift Transactions.
            transactions =
                try JSONDecoder()
                    .decode(
                        [Transaction].self,
                        from: data
                    )

        } catch {

            print(
                "Transaction load error:",
                error
            )
        }
    }
}


// MARK: - Subtle Add Button

// We created this as its own View because the same +
// button is used in several places.
//
// Instead of rebuilding the button every time,
// we can reuse SubtleAddButton.

struct SubtleAddButton: View {

    @Environment(\.colorScheme)
    private var colorScheme

    // This closure contains the action that should happen
    // when the user taps the button.
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            Image(systemName: "plus")
                .font(
                    .system(
                        size: 13,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    colorScheme == .dark
                        ? Color.simplyGreen
                        : Color.simplyDarkGreen
                )
                .frame(
                    width: 29,
                    height: 29
                )
                .background {

                    Circle()
                        .fill(
                            colorScheme == .dark
                                ? Color.simplyGreen.opacity(0.16)
                                : Color.simplyLightGreen
                        )
                }
                .overlay {

                    Circle()
                        .stroke(
                            Color.simplyGreen.opacity(
                                colorScheme == .dark
                                    ? 0.45
                                    : 0.25
                            ),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Category View

// This View displays ONE expense category.
//
// ContentView can reuse it for:
// Gas
// Groceries
// Rent
// Debt
// etc.

struct CategoryView: View {

    let category: TransactionCategory
    let transactions: [Transaction]
    let total: Double

    // These closures let CategoryView tell ContentView
    // that something happened.
    let onAdd: () -> Void
    let onEdit: (Transaction) -> Void

    // Each category remembers whether it is expanded.
    @State private var isExpanded = true

    var body: some View {

        VStack(spacing: 0) {

            HStack(spacing: 12) {

                Image(systemName: category.icon)
                    .foregroundStyle(Color.simplyGreen)
                    .frame(width: 25)

                Button {

                    if !transactions.isEmpty {

                        withAnimation(
                            .easeInOut(duration: 0.2)
                        ) {
                            isExpanded.toggle()
                        }
                    }

                } label: {

                    HStack(spacing: 7) {

                        Text(category.rawValue)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        if !transactions.isEmpty {

                            Image(
                                systemName:
                                    isExpanded
                                        ? "chevron.down"
                                        : "chevron.right"
                            )
                            .font(
                                .system(
                                    size: 11,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if total > 0 {

                    Text(
                        total,
                        format: .currency(code: "USD")
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                SubtleAddButton(
                    action: onAdd
                )
            }
            .padding(.vertical, 4)


            // MARK: Transactions Inside Category

            if isExpanded &&
                !transactions.isEmpty {

                VStack(spacing: 0) {

                    ForEach(transactions) { transaction in

                        Button {

                            onEdit(transaction)

                        } label: {

                            HStack {

                                VStack(
                                    alignment: .leading,
                                    spacing: 3
                                ) {

                                    Text(transaction.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)

                                    Text(
                                        transaction.date,
                                        format:
                                            .dateTime
                                            .month(.abbreviated)
                                            .day()
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(
                                    transaction.amount,
                                    format:
                                        .currency(
                                            code: "USD"
                                        )
                                )
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(
                                    Color.simplyRed
                                )
                            }
                            .padding(.vertical, 9)
                            .padding(.horizontal, 12)
                            .background {

                                RoundedRectangle(
                                    cornerRadius: 10
                                )
                                .fill(
                                    Color.secondary
                                        .opacity(0.075)
                                )
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                    }
                }
                .padding(.leading, 37)
            }
        }
        .padding(.vertical, 3)
    }
}


// MARK: - Transaction Row

// This smaller View is used for displaying deposits.

struct TransactionRow: View {

    let transaction: Transaction

    var body: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(transaction.name)
                    .foregroundStyle(.primary)

                Text(
                    transaction.date,
                    format:
                        .dateTime
                        .month(.abbreviated)
                        .day()
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 2) {

                Text(
                    transaction.isDeposit
                        ? "+"
                        : "-"
                )

                Text(
                    transaction.amount,
                    format:
                        .currency(code: "USD")
                )
            }
            .fontWeight(.semibold)
            .foregroundStyle(
                transaction.isDeposit
                    ? Color.simplyGreen
                    : Color.simplyRed
            )
        }
    }
}


// MARK: - Transaction Editor

// This is the screen that appears when the user
// adds or edits a transaction.

struct TransactionEditorView: View {

    // If transaction is nil, we are adding.
    // If transaction contains something, we are editing.
    let transaction: Transaction?

    let category: TransactionCategory

    // NEW:
    // This contains names from transactions the user
    // has already entered.
    let previousNames: [String]

    // NEW:
    // This tells the editor what date a new
    // transaction should start with.
    let defaultDate: Date

    // onSave lets this View send the completed
    // Transaction back to ContentView.
    let onSave: (Transaction) -> Void

    // dismiss lets us close this sheet.
    @Environment(\.dismiss)
    private var dismiss

    // These State values contain what the user
    // is currently entering into the form.
    @State private var name: String
    @State private var amount: String
    @State private var date: Date
    @State private var isDeposit: Bool


    // MARK: Autocomplete

    // This computed property creates the suggestions
    // that appear underneath the name field.
    //
    // Example:
    //
    // Previous names:
    // Gas
    // Groceries
    // Costco
    //
    // User types:
    // G
    //
    // Results:
    // Gas
    // Groceries

    private var nameSuggestions: [String] {

        // Remove spaces from the beginning/end
        // before we search.
        let typedText =
            name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        // Don't show suggestions before the user types.
        guard !typedText.isEmpty else {
            return []
        }

        return previousNames

            // Keep names that begin with what the user typed.
            .filter { previousName in

                previousName.lowercased().hasPrefix(
                    typedText.lowercased()
                )
                &&
                previousName.caseInsensitiveCompare(name) != .orderedSame
            }

            // Keep the suggestion list from becoming too large.
            .prefix(5)

            // prefix returns a special collection type,
            // so Array() converts it back into a normal array.
            .map { $0 }
    }


    // MARK: Initial Setup

    init(
        transaction: Transaction?,
        category: TransactionCategory,
        startingAsDeposit: Bool,
        previousNames: [String],
        defaultDate: Date,
        onSave: @escaping (Transaction) -> Void
    ) {

        self.transaction = transaction

        self.category =
            transaction?.category
            ?? category

        self.previousNames = previousNames
        self.defaultDate = defaultDate
        self.onSave = onSave


        // If editing, use the existing name.
        // If adding, start with an empty name.
        _name = State(
            initialValue:
                transaction?.name
                ?? ""
        )


        // If editing, show the old amount.
        // Otherwise start empty.
        if let transaction {

            _amount = State(
                initialValue:
                    String(
                        format: "%.2f",
                        transaction.amount
                    )
            )

        } else {

            _amount = State(
                initialValue: ""
            )
        }


        // If editing, keep the old date.
        // If adding, use the default date ContentView sent us.
        _date = State(
            initialValue:
                transaction?.date
                ?? defaultDate
        )


        _isDeposit = State(
            initialValue:
                transaction?.isDeposit
                ?? startingAsDeposit
        )
    }


    // MARK: Editor Screen

    var body: some View {

        NavigationStack {

            Form {

                Section(
                    isDeposit
                        ? "Deposit"
                        : category.rawValue
                ) {

                    TextField(
                        isDeposit
                            ? "Deposit Name"
                            : "Expense Name",
                        text: $name
                    )
                    .textInputAutocapitalization(.words)


                    // NEW:
                    // If we have matching names, show them
                    // immediately underneath the TextField.
                    if !nameSuggestions.isEmpty {

                        ForEach(
                            nameSuggestions,
                            id: \.self
                        ) { suggestion in

                            Button {

                                // Tapping a suggestion puts
                                // that text into the name field.
                                name = suggestion

                            } label: {

                                HStack {

                                    Image(
                                        systemName:
                                            "clock.arrow.circlepath"
                                    )
                                    .foregroundStyle(
                                        Color.simplyGreen
                                    )

                                    Text(suggestion)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Text("Use")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }


                    TextField(
                        "Amount",
                        text: $amount
                    )
                    .keyboardType(.decimalPad)


                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: .date
                    )
                }


                Section("Type") {

                    Picker(
                        "Type",
                        selection: $isDeposit
                    ) {

                        Text("Debit")
                            .tag(false)

                        Text("Deposit")
                            .tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }

            .navigationTitle(
                transaction == nil
                    ? "Add Transaction"
                    : "Edit Transaction"
            )

            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Cancel") {
                        dismiss()
                    }
                }


                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("Save") {
                        save()
                    }
                    .disabled(
                        name
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                        ||
                        Double(amount) == nil
                    )
                }


                // This creates the Done button that
                // appears above the iPhone keyboard.
                ToolbarItemGroup(
                    placement: .keyboard
                ) {

                    Spacer()

                    Button("Done") {

                        UIApplication.shared.sendAction(
                            #selector(
                                UIResponder.resignFirstResponder
                            ),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }


    // MARK: Save From Editor

    private func save() {

        // guard means:
        //
        // "Only continue if these conditions are valid."
        //
        // Here the amount must be a real number
        // and must be greater than zero.

        guard
            let transactionAmount =
                Double(amount),
            transactionAmount > 0
        else {
            return
        }


        // Create the Transaction object that we will
        // send back to ContentView.

        let savedTransaction =
            Transaction(

                // Editing keeps the old ID.
                // Adding creates a new UUID.
                id:
                    transaction?.id
                    ?? UUID(),

                name:
                    name.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),

                amount:
                    transactionAmount,

                date:
                    date,

                isDeposit:
                    isDeposit,

                category:
                    category
            )


        // Send the transaction back to ContentView.
        onSave(savedTransaction)

        // Close the editor.
        dismiss()
    }
}


// MARK: - Balance Editor

// This is the screen used to update Current Balance.

struct BalanceEditorView: View {

    // @Binding is different from @State.
    //
    // The balance actually belongs to ContentView.
    // Binding lets this View read AND change that same value.
    @Binding var currentBalance: Double

    let onSave: () -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var balanceText = ""


    var body: some View {

        NavigationStack {

            Form {

                Section("Current Balance") {

                    TextField(
                        "Balance",
                        text: $balanceText
                    )
                    .keyboardType(.decimalPad)
                }
            }

            .navigationTitle("Update Balance")
            .navigationBarTitleDisplayMode(.inline)

            .onAppear {

                // Convert our Double into text so it
                // can appear inside a TextField.
                balanceText =
                    String(
                        format: "%.2f",
                        currentBalance
                    )
            }

            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Cancel") {
                        dismiss()
                    }
                }


                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("Save") {

                        // Try to turn the text back into a Double.
                        guard
                            let newBalance =
                                Double(balanceText)
                        else {
                            return
                        }

                        // Because currentBalance is a Binding,
                        // this changes the value back in ContentView.
                        currentBalance =
                            newBalance

                        onSave()

                        dismiss()
                    }
                }


                ToolbarItemGroup(
                    placement: .keyboard
                ) {

                    Spacer()

                    Button("Done") {

                        UIApplication.shared.sendAction(
                            #selector(
                                UIResponder.resignFirstResponder
                            ),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}


// MARK: - Preview

// Preview lets Xcode display ContentView
// without needing to launch the entire app.

#Preview {
    ContentView()
}
