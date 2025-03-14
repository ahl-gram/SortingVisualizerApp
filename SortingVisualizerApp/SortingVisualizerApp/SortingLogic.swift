//
//  SortingLogic.swift
//  SortingVisualizerApp
//
//  Created for Sorting Visualizer App
//

import Foundation

/// Pure sorting algorithms without visualization or audio logic
enum SortingLogic {
    
    // MARK: - Sorting Step Types
    
    /// Represents a step in the sorting process
    enum SortingStep<T> {
        /// Comparing two elements
        case compare(Int, Int)
        /// Swapping two elements
        case swap(Int, Int)
        /// Merging operation (specific to merge sort)
        case merge(Int, T)
        /// Marking an element as sorted
        case markSorted(Int)
        /// Algorithm completed
        case completed
    }
    
    /// Callback signature for reporting sorting steps
    typealias StepCallback<T> = (SortingStep<T>, [T]) async -> Bool
    
    // MARK: - Bubble Sort
    
    /// Pure bubble sort algorithm that reports steps through a callback
    /// - Parameters:
    ///   - array: Array to sort
    ///   - onStep: Callback that's called for each step in the algorithm
    /// - Returns: Sorted array
    static func bubbleSort<T: Comparable>(
        array: [T],
        onStep: StepCallback<T>
    ) async -> [T] {
        var arr = array
        let n = arr.count
        
        // Check for empty or single-element array
        if n <= 1 {
            _ = await onStep(.completed, arr)
            return arr
        }
        
        var swapped = false
        
        for i in 0..<n {
            swapped = false
            
            for j in 0..<n - i - 1 {
                // Report comparison step
                let shouldContinue = await onStep(.compare(j, j + 1), arr)
                if !shouldContinue { return arr } // Allow cancellation
                
                if arr[j] > arr[j + 1] {
                    // Swap elements
                    arr.swapAt(j, j + 1)
                    swapped = true
                    
                    // Report swap step
                    let shouldContinue = await onStep(.swap(j, j + 1), arr)
                    if !shouldContinue { return arr } // Allow cancellation
                }
            }
            
            // Mark element as sorted
            let shouldContinue = await onStep(.markSorted(n - i - 1), arr)
            if !shouldContinue { return arr } // Allow cancellation
            
            if !swapped {
                break // Array is sorted
            }
        }
        
        // Report completion
        _ = await onStep(.completed, arr)
        
        return arr
    }
    
    // MARK: - Quick Sort
    
    /// Pure quicksort algorithm that reports steps through a callback
    /// - Parameters:
    ///   - array: Array to sort
    ///   - onStep: Callback that's called for each step in the algorithm
    /// - Returns: Sorted array
    static func quickSort<T: Comparable>(
        array: [T],
        onStep: StepCallback<T>
    ) async -> [T] {
        var arr = array
        
        // Check for empty or single-element array
        if arr.count <= 1 {
            _ = await onStep(.completed, arr)
            return arr
        }
        
        // Start recursive quicksort
        await quickSortHelper(
            array: &arr,
            low: 0,
            high: arr.count - 1,
            onStep: onStep
        )
        
        // Report completion
        _ = await onStep(.completed, arr)
        
        return arr
    }
    
    /// Helper function for quicksort
    private static func quickSortHelper<T: Comparable>(
        array: inout [T],
        low: Int,
        high: Int,
        onStep: StepCallback<T>
    ) async {
        if low >= high {
            // Base case: segment is already sorted
            _ = await onStep(.markSorted(low), array)
            return
        }
        
        // Partition and get pivot index
        let pivotIndex = await partition(
            array: &array,
            low: low,
            high: high,
            onStep: onStep
        )
        
        // Mark pivot as sorted
        _ = await onStep(.markSorted(pivotIndex), array)
        
        // Sort subarrays
        if pivotIndex > low {
            await quickSortHelper(
                array: &array,
                low: low,
                high: pivotIndex - 1,
                onStep: onStep
            )
        }
        
        if pivotIndex < high {
            await quickSortHelper(
                array: &array,
                low: pivotIndex + 1,
                high: high,
                onStep: onStep
            )
        }
    }
    
    /// Partition function for quicksort
    private static func partition<T: Comparable>(
        array: inout [T],
        low: Int,
        high: Int,
        onStep: StepCallback<T>
    ) async -> Int {
        // Use rightmost element as pivot
        let pivot = array[high]
        
        // Report pivot selection
        _ = await onStep(.compare(high, high), array)
        
        // Index of smaller element
        var i = low - 1
        
        // Compare each element with pivot
        for j in low..<high {
            // Report comparison
            let shouldContinue = await onStep(.compare(j, high), array)
            if !shouldContinue { return i + 1 } // Allow cancellation
            
            // If current element <= pivot
            if array[j] < pivot {
                // Increment index of smaller element
                i += 1
                
                // Swap elements
                array.swapAt(i, j)
                
                // Report swap
                _ = await onStep(.swap(i, j), array)
            }
        }
        
        // Swap pivot to its correct position
        i += 1
        array.swapAt(i, high)
        
        // Report final swap
        _ = await onStep(.swap(i, high), array)
        
        return i
    }
    
    // MARK: - Merge Sort
    
    /// Pure merge sort algorithm that reports steps through a callback
    /// - Parameters:
    ///   - array: Array to sort
    ///   - onStep: Callback that's called for each step in the algorithm
    /// - Returns: Sorted array
    static func mergeSort<T: Comparable>(
        array: [T],
        onStep: StepCallback<T>
    ) async -> [T] {
        var arr = array
        
        // Check for empty or single-element array
        if arr.count <= 1 {
            _ = await onStep(.completed, arr)
            return arr
        }
        
        // Start recursive merge sort
        await mergeSortHelper(
            array: &arr,
            start: 0,
            end: arr.count - 1,
            onStep: onStep
        )
        
        // Report completion
        _ = await onStep(.completed, arr)
        
        return arr
    }
    
    /// Helper function for merge sort
    private static func mergeSortHelper<T: Comparable>(
        array: inout [T],
        start: Int,
        end: Int,
        onStep: StepCallback<T>
    ) async {
        // Base case: if the array segment has 1 or fewer elements, it's already sorted
        if start >= end {
            if start == end {
                // Mark the single element as sorted
                _ = await onStep(.markSorted(start), array)
            }
            return
        }
        
        // Find the middle point
        let mid = start + (end - start) / 2
        
        // Sort first and second halves
        await mergeSortHelper(array: &array, start: start, end: mid, onStep: onStep)
        await mergeSortHelper(array: &array, start: mid + 1, end: end, onStep: onStep)
        
        // Merge the sorted halves
        await merge(array: &array, start: start, mid: mid, end: end, onStep: onStep)
    }
    
    /// Merge function for merge sort
    private static func merge<T: Comparable>(
        array: inout [T],
        start: Int,
        mid: Int,
        end: Int,
        onStep: StepCallback<T>
    ) async {
        // Create temporary arrays for the two halves
        let leftSize = mid - start + 1
        let rightSize = end - mid
        
        var leftArray = Array(array[start...(start + leftSize - 1)])
        var rightArray = Array(array[(mid + 1)...end])
        
        // Indexes for traversing the temporary arrays
        var i = 0, j = 0
        // Index for the main array
        var k = start
        
        // Merge the temporary arrays back into the main array
        while i < leftSize && j < rightSize {
            // Compare elements from both arrays
            let shouldContinue = await onStep(.compare(start + i, mid + 1 + j), array)
            if !shouldContinue { return }
            
            if leftArray[i] <= rightArray[j] {
                // If the current element in the left array is smaller
                // than the current element in the right array
                if array[k] != leftArray[i] {
                    // Update the element in the main array
                    array[k] = leftArray[i]
                    
                    // Report as a merge operation with the new value
                    _ = await onStep(.merge(k, leftArray[i]), array)
                }
                i += 1
            } else {
                // If the current element in the right array is smaller
                if array[k] != rightArray[j] {
                    // Update the element in the main array
                    array[k] = rightArray[j]
                    
                    // Report as a merge operation with the new value
                    _ = await onStep(.merge(k, rightArray[j]), array)
                }
                j += 1
            }
            k += 1
        }
        
        // Copy any remaining elements from the left array
        while i < leftSize {
            if array[k] != leftArray[i] {
                array[k] = leftArray[i]
                _ = await onStep(.merge(k, leftArray[i]), array)
            }
            i += 1
            k += 1
        }
        
        // Copy any remaining elements from the right array
        while j < rightSize {
            if array[k] != rightArray[j] {
                array[k] = rightArray[j]
                _ = await onStep(.merge(k, rightArray[j]), array)
            }
            j += 1
            k += 1
        }
        
        // Mark all elements in this merged segment as sorted
        for index in start...end {
            _ = await onStep(.markSorted(index), array)
        }
    }
}
