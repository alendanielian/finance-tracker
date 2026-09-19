enum EntryType { income, expense }

EntryType entryTypeFromString(String value) =>
    value == EntryType.income.name ? EntryType.income : EntryType.expense;
