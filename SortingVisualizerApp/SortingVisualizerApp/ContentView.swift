//
//  ContentView.swift
//  SortingVisualizerApp
//
//  Created by Alexander Lee on 3/13/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var arraySize: Double = 50
    @State private var animationSpeed: Double = 1.0
    @StateObject private var viewModel = SortingViewModel()
    @State private var safeAreaInsets: EdgeInsets = EdgeInsets()
    @State private var arraySizeDebounceTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Add safe area insets reader to capture dynamic island and other insets
                SafeAreaInsetsReader(insets: $safeAreaInsets)
                
                VStack(spacing: 0) {
                    Text("Sorting Visualizer")
                        .font(.title)
                        .padding(.top, 5)
                    
                    // Sorting visualization area with proper insets
                    if viewModel.bars.isEmpty {
                        Text("Press 'Randomize Array' to start")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .padding(.horizontal, geometry.size.width > geometry.size.height ? 16 : 5)
                    } else {
                        // Calculate the width for each bar to fill the available space
                        // while respecting safe areas
                        GeometryReader { vizGeometry in
                            // Calculate total available width - accounting for safe areas
                            // We want the visualization to align with the actual content of the control panel
                            // not including its padding
                            let availableWidth = vizGeometry.size.width - (safeAreaInsets.leading)/4 - (safeAreaInsets.trailing)/4
                            let barCount = viewModel.bars.count
                            
                            // Use smaller spacing for more bars to maximize space usage
                            let barSpacing: CGFloat = barCount > 60 ? 1 : 2
                            
                            // Calculate total width used by spacing between bars
                            let totalSpacingWidth = barSpacing * CGFloat(barCount - 1)
                            
                            // Calculate width per bar - ensure we fill the available space
                            let barWidth = max(1, (availableWidth - totalSpacingWidth) / CGFloat(barCount))
                            
                            // Calculate maximum bar height to prevent overlap with control panel
                            // Use 95% of the available height to ensure we leave space for the control panel
                            let maxAvailableHeight = vizGeometry.size.height * 0.95
                            
                            // Find the max value in the array to normalize heights
                            let maxBarValue = viewModel.bars.map { $0.value }.max() ?? 200
                            
                            HStack(alignment: .bottom, spacing: barSpacing) {
                                ForEach(viewModel.bars) { bar in
                                    // Normalize height to fit within available space
                                    let normalizedHeight = CGFloat(bar.value) / CGFloat(maxBarValue) * maxAvailableHeight
                                    
                                    SortingBarView(
                                        height: normalizedHeight,
                                        state: bar.state,
                                        width: barWidth
                                    )
                                }
                            }
                            .frame(width: availableWidth, height: vizGeometry.size.height, alignment: .bottom)
                            .background(Color.black)
                            // Center the visualization in the available space
                            .position(x: vizGeometry.size.width / 2, y: vizGeometry.size.height / 2)
                        }
                        // Remove padding so bars span the full width
                        .padding(.horizontal, 0)
                    }
                    
                    Spacer(minLength: 10)
                    
                    // Control panel components - adaptive layout based on orientation
                    if geometry.size.width > geometry.size.height {
                        // Landscape mode - wider control panel
                        ControlPanelView(
                            arraySize: $arraySize,
                            animationSpeed: $animationSpeed,
                            isAudioEnabled: $viewModel.isAudioEnabled,
                            selectedAlgorithm: $viewModel.selectedAlgorithm,
                            onRandomize: {
                                viewModel.randomizeArray(size: Int(arraySize))
                            },
                            onStartSorting: {
                                viewModel.startSorting(animationSpeed: animationSpeed)
                            },
                            onStopSorting: {
                                viewModel.stopSorting()
                            },
                            isSorting: viewModel.isSorting
                        )
                        .padding(.horizontal, 5)
                        .padding(.bottom, 5)
                        .background(Color.black.opacity(0.1))
                        // Set minimum height for the control panel to ensure all controls are visible
                        .frame(minHeight: 180)
                    } else {
                        // Portrait mode - more compact control panel
                        CompactControlPanelView(
                            arraySize: $arraySize,
                            animationSpeed: $animationSpeed,
                            isAudioEnabled: $viewModel.isAudioEnabled,
                            selectedAlgorithm: $viewModel.selectedAlgorithm,
                            onRandomize: {
                                viewModel.randomizeArray(size: Int(arraySize))
                            },
                            onStartSorting: {
                                viewModel.startSorting(animationSpeed: animationSpeed)
                            },
                            onStopSorting: {
                                viewModel.stopSorting()
                            },
                            isSorting: viewModel.isSorting
                        )
                        .padding(.horizontal, 0)
                        .padding(.bottom, 5)
                        .background(Color.black.opacity(0.1))
                    }
                }
                // Don't ignore safe areas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .avoidDynamicIsland()
                .onAppear {
                    // Initialize with a random array
                    viewModel.randomizeArray(size: Int(arraySize))
                }
                .onChange(of: arraySize) { newSize in
                    // Don't update during sorting
                    guard !viewModel.isSorting else { return }
                    
                    // Cancel any existing timer
                    arraySizeDebounceTimer?.invalidate()
                    
                    // Debounce the array generation to avoid performance issues during slider dragging
                    arraySizeDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                        viewModel.randomizeArray(size: Int(newSize))
                    }
                }
                
                // Show completion animation when sorting is complete
                if viewModel.showCompletionAnimation {
                    CompletionAnimationView()
                        .onTapGesture {
                            withAnimation {
                                viewModel.showCompletionAnimation = false
                            }
                        }
                }
            }
        }
        .respectSafeAreas() // Use our custom modifier instead of ignoring safe areas
    }
}

// Compact version of control panel for portrait mode
struct CompactControlPanelView: View {
    @Binding var arraySize: Double
    @Binding var animationSpeed: Double
    @Binding var isAudioEnabled: Bool
    @Binding var selectedAlgorithm: SortingAlgorithmType
    var onRandomize: () -> Void
    var onStartSorting: () -> Void
    var onStopSorting: () -> Void
    var isSorting: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            // Top row with controls label and audio toggle
            HStack {
                Text("Controls")
                    .font(.headline)
                
                Spacer()
                
                Toggle(isOn: $isAudioEnabled) {
                    Text("Audio")
                        .font(.callout)
                }
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            
            // Algorithm picker
            HStack {
                Text("Algorithm:")
                    .font(.caption)
                
                Picker("Algorithm", selection: $selectedAlgorithm) {
                    ForEach(SortingAlgorithmType.allCases) { algorithm in
                        Text(algorithm.rawValue).tag(algorithm)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .disabled(isSorting)
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 2)
            
            // Array Size slider
            HStack {
                Text("Size: \(Int(arraySize))")
                    .font(.caption)
                    .frame(width: 55, alignment: .leading)
                Slider(value: $arraySize, in: 10...100, step: 1)
                    .disabled(isSorting)
            }
            
            // Animation Speed slider
            HStack {
                Text("Speed: \(String(format: "%.1f", animationSpeed))x")
                    .font(.caption)
                    .frame(width: 55, alignment: .leading)
                Slider(value: $animationSpeed, in: 0.1...20.0, step: 0.1)
            }
            
            // Buttons in a row
            HStack(spacing: 8) {
                Button(action: onRandomize) {
                    Text("Randomize")
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .font(.callout)
                }
                .disabled(isSorting)
                
                if isSorting {
                    Button(action: onStopSorting) {
                        Text("Stop")
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .font(.callout)
                    }
                } else {
                    Button(action: onStartSorting) {
                        Text("Start")
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .font(.callout)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}

#Preview("Portrait") {
    ContentView()
        .previewInterfaceOrientation(.portrait)
}

#Preview("Landscape") {
    ContentView()
        .previewInterfaceOrientation(.landscapeLeft)
}
