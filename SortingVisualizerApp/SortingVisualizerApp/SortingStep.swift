/// Represents a step in the sorting process
enum SortingStep<T> {
    case compare(Int, Int)
    case swap(Int, Int)
    case merge(Int, T)
    case markSorted(Int)
    case bucket(Int, Int)
    case highlight(Int)     // Highlight an element (for cube visualization)
    case unhighlight(Int)   // Remove highlight from an element
    case completed
}

/// Callback signature for reporting sorting steps
enum SortingStepType {
    typealias StepCallback<T> = (SortingStep<T>, [T]) async -> Bool
}