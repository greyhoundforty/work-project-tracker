// EngagementTracker/Views/Sheets/TemplatePickerView.swift
import SwiftUI

struct TemplatePickerView: View {
    let templates: [ProjectTemplate]
    @Binding var selected: ProjectTemplate?
    let onContinue: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("New Project")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.themeFg)
                Spacer()
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Continue") { onContinue() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.themeAqua)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color.themeBg1)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHOOSE A TEMPLATE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.themeFgDim)
                        .padding(.bottom, 4)

                    TemplatePickerRow(
                        name: "Blank Project",
                        stage: nil,
                        taskCount: 0,
                        customFieldCount: 0,
                        isSelected: selected == nil,
                        onSelect: { selected = nil }
                    )

                    ForEach(templates) { template in
                        TemplatePickerRow(
                            name: template.name,
                            stage: template.stage,
                            taskCount: template.taskTitles.count,
                            customFieldCount: template.customFields.count,
                            isSelected: selected?.id == template.id,
                            onSelect: { selected = template }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color.themeBg)
        .frame(width: 480)
    }
}

private struct TemplatePickerRow: View {
    let name: String
    let stage: String?
    let taskCount: Int
    let customFieldCount: Int
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.themeAqua : Color.themeFgDim)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.themeFg)
                    HStack(spacing: 8) {
                        if let stage {
                            Text(stage)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.themeFgDim)
                        }
                        if taskCount > 0 {
                            Text("\(taskCount) task\(taskCount == 1 ? "" : "s")")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.themeFgDim)
                        }
                        if customFieldCount > 0 {
                            Text("\(customFieldCount) field\(customFieldCount == 1 ? "" : "s")")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.themeFgDim)
                        }
                    }
                }
                Spacer()
            }
            .padding(10)
            .background(isSelected ? Color.themeAqua.opacity(0.12) : Color.themeBg1)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
