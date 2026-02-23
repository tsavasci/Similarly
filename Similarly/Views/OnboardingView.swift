//
//  OnboardingView.swift
//  Similarly
//
//  Created by AI Agent
//

import SwiftUI

/// İlk kullanım karşılama ekranı
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "photo.stack.fill",
            title: L10n.t("onboarding.page1.title"),
            description: L10n.t("onboarding.page1.desc"),
            gradient: [.blue, .purple]
        ),
        OnboardingPage(
            icon: "sparkles",
            title: L10n.t("onboarding.page2.title"),
            description: L10n.t("onboarding.page2.desc"),
            gradient: [.purple, .pink]
        ),
        OnboardingPage(
            icon: "hand.thumbsup.fill",
            title: L10n.t("onboarding.page3.title"),
            description: L10n.t("onboarding.page3.desc"),
            gradient: [.pink, .orange]
        ),
        OnboardingPage(
            icon: "internaldrive",
            title: L10n.t("onboarding.page4.title"),
            description: L10n.t("onboarding.page4.desc"),
            gradient: [.orange, .red]
        ),
    ]

    var body: some View {
        ZStack {
            // Gradient arka plan
            LinearGradient(
                colors: pages[currentPage].gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Atla butonu
                HStack {
                    Spacer()
                    Button(action: {
                        completeOnboarding()
                    }) {
                        Text(L10n.k("common.skip"))
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Ana içerik
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Spacer()

                // Alt butonlar
                VStack(spacing: 20) {
                    // Sayfa göstergesi
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.bottom, 10)

                    // Butonlar
                    HStack(spacing: 15) {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text(L10n.k("common.back"))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                        }

                        Button(action: {
                            if currentPage < pages.count - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            HStack {
                                Text(
                                    currentPage < pages.count - 1
                                        ? L10n.k("common.next") : L10n.k("common.start")
                                )
                                    .fontWeight(.semibold)
                                if currentPage < pages.count - 1 {
                                    Image(systemName: "chevron.right")
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(pages[currentPage].gradient[0])
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasSeenOnboarding = true
            isPresented = false
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 30) {
            // İkon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 160, height: 160)

                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)

            // Metin
            VStack(spacing: 15) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(isPresented: .constant(true))
}
