//
//  Annotations.swift
//  PageKeep
//
//  Created by Allie Sumner on 10/7/25.
//

// SwiftData model for book annotations (quotes/passages)
// Includes 11 genre-specific color palettes (110 total colors)
// Each annotation belongs to one Book
// NEW: Supports text formatting (underline/strikethrough)
// FIXED: All color IDs now match exact asset names

import Foundation
import SwiftData
import SwiftUI

@Model
final class Annotation {
    var id: UUID
    var text: String              // The quote/passage text
    var pageNumber: Int            // Page number where quote appears
    var personalNotes: String?     // Optional notes about why it matters
    var color: String?             // Color coding (stored as string)
    var genre: String?             // Genre palette used (stored as string)
    var formattingData: Data?      // NEW: Stores text formatting (underline/strikethrough)
    var dateCreated: Date
    var dateModified: Date
    
    // Relationship to Book
    var book: Book?
    
    init(text: String,
         pageNumber: Int,
         personalNotes: String? = nil,
         color: String? = nil,
         genre: AnnotationGenre? = nil,
         formattingData: Data? = nil,
         book: Book? = nil) {
        self.id = UUID()
        self.text = text
        self.pageNumber = pageNumber
        self.personalNotes = personalNotes
        self.color = color
        self.genre = genre?.rawValue ?? AnnotationGenre.general.rawValue
        self.formattingData = formattingData
        self.dateCreated = Date()
        self.dateModified = Date()
        self.book = book
    }
    
    // Helper computed property for genre
    var annotationGenre: AnnotationGenre {
        get {
            guard let genreString = genre else { return .general }
            return AnnotationGenre(rawValue: genreString) ?? .general
        }
        set {
            genre = newValue.rawValue
        }
    }
    
    // Get meaningful color name based on genre
    var colorMeaningfulName: String {
        guard let colorId = color else { return "" }
        
        // Find the color in the current genre palette
        if let colorDef = annotationGenre.colors.first(where: { $0.id == colorId }) {
            return colorDef.name
        }
        
        // Fallback: search all genres (in case genre was changed but color wasn't)
        for genre in AnnotationGenre.allCases {
            if let colorDef = genre.colors.first(where: { $0.id == colorId }) {
                return colorDef.name
            }
        }
        
        return ""
    }
    
    // Get display color
    var displayColor: Color {
        guard let colorId = color else { return Color(.systemGray) }
        
        // Try to get the color from Assets catalog
        return Color(colorId)
    }
    
    // Lighter version for backgrounds
    var lightColor: Color {
        return displayColor.opacity(0.2)
    }
}

// MARK: - Genre System

enum AnnotationGenre: String, CaseIterable, Identifiable, Codable {
    case general = "general"
    case romance = "romance"
    case mystery = "mystery"
    case fantasy = "fantasy"
    case sciFi = "scifi"
    case horror = "horror"
    case thriller = "thriller"
    case superhero = "superhero"
    case fiction = "fiction"
    case biography = "biography"
    case education = "education"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .romance: return "Romance"
        case .mystery: return "Mystery"
        case .fantasy: return "Fantasy"
        case .sciFi: return "Sci-Fi"
        case .horror: return "Horror"
        case .thriller: return "Thriller"
        case .superhero: return "Superhero"
        case .fiction: return "Fiction"
        case .biography: return "Biography"
        case .education: return "Education"
        }
    }
    
    var colors: [AnnotationColor] {
        switch self {
        case .general:
            return [
                AnnotationColor(id: "AnnotationTeal", displayName: "Teal", name: "Funny"),
                AnnotationColor(id: "AnnotationYellow", displayName: "Yellow", name: "Hopeful"),
                AnnotationColor(id: "AnnotationPurple", displayName: "Purple", name: "Sad"),
                AnnotationColor(id: "AnnotationGreen", displayName: "Green", name: "Thoughtful"),
                AnnotationColor(id: "AnnotationPink", displayName: "Pink", name: "Love"),
                AnnotationColor(id: "AnnotationOrange", displayName: "Orange", name: "Exciting"),
                AnnotationColor(id: "AnnotationRed", displayName: "Red", name: "Angry"),
                AnnotationColor(id: "AnnotationBlue", displayName: "Blue", name: "Peaceful")
            ]
            
        case .romance:
            return [
                AnnotationColor(id: "romanceMeetcute", displayName: "Blush Pink", name: "Meet-cute"),
                AnnotationColor(id: "romanceChemistry", displayName: "Electric Blue", name: "Chemistry"),
                AnnotationColor(id: "romanceFluff", displayName: "Soft Yellow", name: "Fluff"),
                AnnotationColor(id: "romanceFeels", displayName: "Deep Purple", name: "Feels"),
                AnnotationColor(id: "romanceSteamy", displayName: "Crimson", name: "Steamy"),
                AnnotationColor(id: "romancePining", displayName: "Dusty Rose", name: "Pining"),
                AnnotationColor(id: "romanceAngst", displayName: "Storm Gray", name: "Angst"),
                AnnotationColor(id: "romanceDark", displayName: "Midnight", name: "Dark"),
                AnnotationColor(id: "romanceHeartbreak", displayName: "Ice Blue", name: "Heartbreak"),
                AnnotationColor(id: "romanceHea", displayName: "Sunset Gold", name: "HEA")
            ]
            
        case .mystery:
            return [
                AnnotationColor(id: "mysteryClues", displayName: "Evidence Blue", name: "Clues"),
                AnnotationColor(id: "mysteryRedherrings", displayName: "Deception Red", name: "Red Herrings"),
                AnnotationColor(id: "mysterySuspects", displayName: "Shadow Gray", name: "Suspects"),
                AnnotationColor(id: "mysteryAlibis", displayName: "Truth Green", name: "Alibis"),
                AnnotationColor(id: "mysteryMotives", displayName: "Blood Orange", name: "Motives"),
                AnnotationColor(id: "mysteryContradictions", displayName: "Paradox Purple", name: "Contradictions"),
                AnnotationColor(id: "mysteryWitness", displayName: "Testimony Teal", name: "Witness"),
                AnnotationColor(id: "mysteryConnections", displayName: "Link Gold", name: "Connections"),
                AnnotationColor(id: "mysteryHunch", displayName: "Intuition Indigo", name: "Hunch"),
                AnnotationColor(id: "mysteryReveal", displayName: "Revelation White", name: "Reveal")
            ]
            
        case .fantasy:
            return [
                AnnotationColor(id: "FantasyForeshadowing", displayName: "Prophecy Purple", name: "Foreshadowing"),
                AnnotationColor(id: "FantasyMagic", displayName: "Mystic Blue", name: "Magic Systems"),
                AnnotationColor(id: "FantasyMythology", displayName: "Ancient Gold", name: "Mythology/Lore"),
                AnnotationColor(id: "FantasyWorldbuilding", displayName: "Realm Green", name: "World Building"),
                AnnotationColor(id: "FantasyBattles", displayName: "War Red", name: "Battles"),
                AnnotationColor(id: "FantasyDarkforces", displayName: "Shadow Black", name: "Dark Forces"),
                AnnotationColor(id: "FantasyEpic", displayName: "Glory Orange", name: "Epic"),
                AnnotationColor(id: "FantasyPolitics", displayName: "Court Silver", name: "Politics"),
                AnnotationColor(id: "FantasyCreatures", displayName: "Beast Brown", name: "Creatures"),
                AnnotationColor(id: "FantasyBonds", displayName: "Soul Teal", name: "Bonds")
            ]
            
        case .sciFi:
            return [
                AnnotationColor(id: "ScifiTech", displayName: "Circuit Green", name: "Tech/Science"),
                AnnotationColor(id: "ScifiWorldbuilding", displayName: "Nebula Purple", name: "World Building"),
                AnnotationColor(id: "ScifiTime", displayName: "Temporal Blue", name: "Time Elements"),
                AnnotationColor(id: "ScifiSpace", displayName: "Cosmic Black", name: "Space/Aliens"),
                AnnotationColor(id: "ScifiSocial", displayName: "Dystopia Gray", name: "Social Commentary"),
                AnnotationColor(id: "ScifiPredictions", displayName: "Future Gold", name: "Predictions"),
                AnnotationColor(id: "ScifiAi", displayName: "Digital Cyan", name: "AI/Robots"),
                AnnotationColor(id: "ScifiPhilosophy", displayName: "Question White", name: "Philosophy"),
                AnnotationColor(id: "ScifiAction", displayName: "Laser Red", name: "Action"),
                AnnotationColor(id: "ScifiWarnings", displayName: "Alert Orange", name: "Warnings")
            ]
            
        case .horror:
            return [
                AnnotationColor(id: "HorrorAtmosphere", displayName: "Fog Gray", name: "Atmosphere"),
                AnnotationColor(id: "HorrorForeshadowing", displayName: "Omen Black", name: "Foreshadowing"),
                AnnotationColor(id: "HorrorDread", displayName: "Dread Purple", name: "Dread"),
                AnnotationColor(id: "HorrorJumpscares", displayName: "Shock Red", name: "Jump Scares"),
                AnnotationColor(id: "HorrorSupernatural", displayName: "Ghost White", name: "Supernatural"),
                AnnotationColor(id: "HorrorDisturbing", displayName: "Sick Green", name: "Disturbing"),
                AnnotationColor(id: "HorrorGore", displayName: "Blood Red", name: "Gore"),
                AnnotationColor(id: "HorrorVictims", displayName: "Innocent Blue", name: "Victims"),
                AnnotationColor(id: "HorrorSafe", displayName: "Haven Gold", name: "Safe"),
                AnnotationColor(id: "HorrorNightmare", displayName: "Terror Orange", name: "Nightmare Fuel")
            ]
            
        case .thriller:
            return [
                AnnotationColor(id: "ThrillerSetup", displayName: "Foundation Gray", name: "Setup"),
                AnnotationColor(id: "ThrillerUnease", displayName: "Tension Yellow", name: "Unease"),
                AnnotationColor(id: "ThrillerClues", displayName: "Breadcrumb Blue", name: "Clues"),
                AnnotationColor(id: "ThrillerTrust", displayName: "Doubt Purple", name: "Trust?"),
                AnnotationColor(id: "ThrillerMindgames", displayName: "Psych Green", name: "Mind Games"),
                AnnotationColor(id: "ThrillerWarning", displayName: "Caution Orange", name: "Warning"),
                AnnotationColor(id: "ThrillerThreat", displayName: "Danger Red", name: "Threat"),
                AnnotationColor(id: "ThrillerChase", displayName: "Pursuit Black", name: "Chase"),
                AnnotationColor(id: "ThrillerDanger", displayName: "Crisis Crimson", name: "Danger"),
                AnnotationColor(id: "ThrillerRevelation", displayName: "Truth White", name: "Revelation")
            ]
            
        case .superhero:
            return [
                AnnotationColor(id: "SuperheroOrigin", displayName: "Genesis Gold", name: "Origin"),
                AnnotationColor(id: "SuperheroIdentity", displayName: "Mask Black", name: "Identity"),
                AnnotationColor(id: "SuperheroPowers", displayName: "Power Blue", name: "Powers"),
                AnnotationColor(id: "SuperheroWeakness", displayName: "Kryptonite Green", name: "Weakness"),
                AnnotationColor(id: "SuperheroHeromoment", displayName: "Triumph Red", name: "Hero Moment"),
                AnnotationColor(id: "SuperheroVillain", displayName: "Nemesis Purple", name: "Villain"),
                AnnotationColor(id: "SuperheroTeam", displayName: "Alliance Orange", name: "Team"),
                AnnotationColor(id: "SuperheroMentor", displayName: "Wisdom Gray", name: "Mentor"),
                AnnotationColor(id: "SuperheroCost", displayName: "Sacrifice Brown", name: "Cost"),
                AnnotationColor(id: "SuperheroChoice", displayName: "Decision Teal", name: "Choice")
            ]
            
        case .fiction:
            return [
                AnnotationColor(id: "FictionBeautiful", displayName: "Prose Purple", name: "Beautiful Writing"),
                AnnotationColor(id: "FictionCharacter", displayName: "Soul Blue", name: "Character Moments"),
                AnnotationColor(id: "FictionThemes", displayName: "Deep Green", name: "Themes"),
                AnnotationColor(id: "FictionEmotional", displayName: "Heart Red", name: "Emotional"),
                AnnotationColor(id: "FictionSymbolism", displayName: "Metaphor Gold", name: "Symbolism"),
                AnnotationColor(id: "FictionForeshadowing", displayName: "Future Gray", name: "Foreshadowing"),
                AnnotationColor(id: "FictionPlot", displayName: "Story Orange", name: "Plot Points"),
                AnnotationColor(id: "FictionQuotes", displayName: "Words Teal", name: "Quotes"),
                AnnotationColor(id: "FictionFunny", displayName: "Humor Yellow", name: "Funny"),
                AnnotationColor(id: "FictionQuestions", displayName: "Wonder White", name: "Questions")
            ]
            
        case .biography:
            return [
                AnnotationColor(id: "BiographyLessons", displayName: "Wisdom Gold", name: "Life Lessons"),
                AnnotationColor(id: "BiographyTurning", displayName: "Pivot Red", name: "Turning Points"),
                AnnotationColor(id: "BiographyHistorical", displayName: "Era Brown", name: "Historical Context"),
                AnnotationColor(id: "BiographyTraits", displayName: "Character Blue", name: "Character Traits"),
                AnnotationColor(id: "BiographyRelationships", displayName: "Connection Green", name: "Relationships"),
                AnnotationColor(id: "BiographyStruggles", displayName: "Challenge Gray", name: "Struggles"),
                AnnotationColor(id: "BiographyTriumphs", displayName: "Victory Orange", name: "Triumphs"),
                AnnotationColor(id: "BiographyQuotes", displayName: "Words Purple", name: "Quotes"),
                AnnotationColor(id: "BiographyTimeline", displayName: "Timeline Teal", name: "Timeline"),
                AnnotationColor(id: "BiographyParallels", displayName: "Mirror Black", name: "Parallels")
            ]
            
        case .education:
            return [
                AnnotationColor(id: "EducationConcepts", displayName: "Theory Blue", name: "Key Concepts"),
                AnnotationColor(id: "EducationExamples", displayName: "Practice Green", name: "Examples"),
                AnnotationColor(id: "EducationFormulas", displayName: "Equation Purple", name: "Formulas"),
                AnnotationColor(id: "EducationFacts", displayName: "Truth Orange", name: "Important Facts"),
                AnnotationColor(id: "EducationQuestions", displayName: "Unclear Red", name: "Questions/Unclear"),
                AnnotationColor(id: "EducationPriority", displayName: "Star Gold", name: "Study Priority"),
                AnnotationColor(id: "EducationReferences", displayName: "Link Teal", name: "Cross-References"),
                AnnotationColor(id: "EducationMethodology", displayName: "Process Gray", name: "Methodology"),
                AnnotationColor(id: "EducationConclusions", displayName: "Summary Black", name: "Conclusions/Summaries"),
                AnnotationColor(id: "EducationApplication", displayName: "Use Brown", name: "Personal Application")
            ]
        }
    }
}

// MARK: - Color Definition

struct AnnotationColor: Identifiable {
    let id: String              // Color asset name (EXACT match to asset catalog)
    let displayName: String     // Display name in picker (e.g., "Teal")
    let name: String            // Context name (e.g., "Funny")
    
    var color: Color {
        Color(id)
    }
}
