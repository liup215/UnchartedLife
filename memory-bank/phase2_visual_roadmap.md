# Phase 2 Visual Roadmap

## Current State → Future State Transformation

```
┌─────────────────────────────────────────────────────────────────┐
│                    CURRENT STATE (Phase 1)                      │
│                                                                 │
│  ✅ Data-Driven Architecture                                    │
│  ✅ Component System (Health, Inventory, Combat)                │
│  ✅ Combat Mechanics (Weapons, Attacks)                         │
│  ✅ Battle-Quiz Prototype (Bio Blitz)                           │
│  ✅ Dialogue & Quest Systems                                    │
│  ✅ Multiple Choice Questions                                   │
│                                                                 │
│  🔴 Limited to Multiple Choice Only                             │
│  🔴 Generic Combat (No Educational Integration)                 │
│  🔴 Biology Content (Wrong Subject)                             │
│  🔴 No Unique Differentiators                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Phase 2 Transformation
                              │ (10-12 Weeks)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  TARGET STATE (Phase 2 End)                     │
│                                                                 │
│  ✅ Offline Evaluation Engine (Python + SymPy)                  │
│  ✅ Knowledge Pen System (点墨, 挥毫, 题眼勘破)                     │
│  ✅ Ink Energy Resource (文气)                                   │
│  ✅ Knowledge Lock (VATS-like Mechanic)                         │
│  ✅ Book-Soul Seal System (书魂印)                               │
│  ✅ Open-Ended Math Questions                                   │
│  ✅ Math Content (Grades 1-12)                                  │
│  ✅ Complete Knowledge-Combat Integration                       │
│                                                                 │
│  → Unique Educational Game Identity                             │
│  → Ready for Alpha Testing                                      │
│  → Foundation for Advanced Features (Phase 3)                   │
└─────────────────────────────────────────────────────────────────┘
```

## Timeline Visualization

```
Phase 2: Knowledge-Combat Integration (12 Weeks)
═══════════════════════════════════════════════════════════════

Week 1-2: Offline Evaluation Engine ⚡ [CRITICAL PATH]
├─ Python Flask/FastAPI Server
├─ SymPy Integration
├─ HTTP Client in Godot
├─ Equation Solver
├─ Expression Evaluator
└─ Testing & Benchmarking
    └─ Deliverable: Can evaluate "2x + 5 = 13, x=?" ✓

Week 3-4: Knowledge Pen & Ink Energy 🖊️
├─ InkEnergyComponent
├─ Pen Actions (点墨, 挥毫)
├─ Knowledge Lock State Machine
├─ Hint System (题眼勘破)
├─ Bullet-time Integration
└─ UI for Ink Display
    └─ Deliverable: Knowledge Lock Combat Loop ✓

Week 5-6: Book-Soul Seal System 📖
├─ BookSoulSealData Resource
├─ SealManager Autoload
├─ Primary Seal (主魂印)
├─ Secondary Seal (辅魂印)
├─ Seal Inventory UI
├─ Seal Equipment System
└─ Combat Integration
    └─ Deliverable: Seal Progression System ✓

Week 7-8: Enhanced Question System 📝
├─ QuestionDataV2 Resource
├─ Fill-in-Blank UI
├─ Equation Input Widget
├─ Multi-Step Problems
├─ Hint System Integration
└─ 50+ Sample Questions
    └─ Deliverable: Rich Question Types ✓

Week 9-10: Content Migration & Polish 🧹
├─ Remove Vehicle System
├─ Remove Biology Content
├─ Create Math Question Bank (100+)
├─ Update Documentation
├─ Bug Fixes
└─ Performance Optimization
    └─ Deliverable: Clean Math-Focused Game ✓

Week 11: Integration Testing
└─ End-to-end testing of complete loop

Week 12: Final Polish & Documentation
└─ Phase 2 Complete ✓
```

## System Integration Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         PLAYER                                  │
│                                                                 │
│  ┌──────────────┐        ┌──────────────┐                      │
│  │ Ink Energy   │◄───────│ Combat       │                      │
│  │ Component    │        │ Actions      │                      │
│  └──────┬───────┘        └──────────────┘                      │
│         │                                                        │
│         │ Reaches Threshold                                     │
│         ▼                                                        │
│  ┌──────────────────────────────────┐                          │
│  │   Knowledge Lock Activated       │                          │
│  │   (Bullet-time + Question)       │                          │
│  └───────────┬──────────────────────┘                          │
│              │                                                   │
│              │ Send Answer                                      │
│              ▼                                                   │
│  ┌─────────────────────────────────────────┐                   │
│  │    Evaluation Client (Autoload)         │                   │
│  └────────────┬────────────────────────────┘                   │
└───────────────┼──────────────────────────────────────────────────┘
                │ HTTP Request
                ▼
┌───────────────────────────────────────────────────────────────┐
│           Python Evaluation Service (Local)                   │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  SymPy Evaluator                                     │    │
│  │  - Parse equation: "2x + 5 = 13"                     │    │
│  │  - Solve: x = 4                                      │    │
│  │  - Compare student answer                            │    │
│  │  - Return result (correct/incorrect)                 │    │
│  └─────────────────────────────────────────────────────┘    │
└────────────────┬──────────────────────────────────────────────┘
                 │ HTTP Response
                 ▼
┌───────────────────────────────────────────────────────────────┐
│                    Back to Game                               │
│                                                               │
│  If Correct:                    If Incorrect:                │
│  ├─ Execute Finishing Move      ├─ Apply Penalty             │
│  ├─ Defeat Enemy                ├─ Reset Ink Energy          │
│  ├─ Award Seal                  └─ Stagger Player            │
│  └─ Progress Story                                           │
└───────────────────────────────────────────────────────────────┘
```

## Knowledge-Combat Loop Flow

```
┌────────────────────────────────────────────────────────────┐
│                    COMBAT PHASE                            │
│                                                            │
│  Player Action:                                            │
│  ┌────────┐    ┌────────┐    ┌────────┐                   │
│  │ 点墨    │───▶│ 挥毫    │───▶│ Dodge  │                   │
│  │ (Dot)  │    │(Sweep) │    │        │                   │
│  └────────┘    └────────┘    └────────┘                   │
│                     │                                       │
│                     │ Generates                             │
│                     ▼                                       │
│              ┌──────────────┐                              │
│              │ Ink Energy   │ ████████░░ (80%)            │
│              └──────────────┘                              │
│                     │                                       │
│                     │ Reaches 100%                          │
│                     ▼                                       │
└─────────────────────┼──────────────────────────────────────┘
                      │
                      │ Activate Knowledge Lock
                      ▼
┌────────────────────────────────────────────────────────────┐
│              KNOWLEDGE LOCK PHASE                          │
│                                                            │
│  ⏱️ Time Scale: 0.2x (Slow Motion)                        │
│  📝 Question Appears:                                      │
│                                                            │
│  ┌──────────────────────────────────────────┐            │
│  │  Solve for x:                             │            │
│  │  2x + 5 = 13                              │            │
│  │                                            │            │
│  │  Your Answer: [_______]                   │            │
│  │                                            │            │
│  │  💡 Hint (Cost: 20 Ink)                   │            │
│  └──────────────────────────────────────────┘            │
│                     │                                       │
│                     │ Player Answers                        │
│                     ▼                                       │
│            ┌─────────────────┐                            │
│            │ Evaluation      │                            │
│            │ (Python SymPy)  │                            │
│            └────────┬────────┘                            │
│                     │                                       │
│       ┌─────────────┴─────────────┐                       │
│       │                           │                        │
│       ▼                           ▼                        │
│  ✅ Correct                    ❌ Incorrect                │
└───────┼───────────────────────────┼───────────────────────┘
        │                           │
        ▼                           ▼
┌────────────────────┐    ┌────────────────────┐
│  FINISHING MOVE    │    │    PENALTY         │
│                    │    │                    │
│  ⚡ 破妄一击        │    │  😵 Stagger        │
│  💥 Massive Damage │    │  ⚡ Reset Ink      │
│  ⭐ +Experience    │    │  ❤️ Take Damage    │
│                    │    │                    │
│  └─▶ Enemy Defeated│    │  └─▶ Try Again     │
└────────────────────┘    └────────────────────┘
        │
        │ Boss Defeated
        ▼
┌────────────────────────────────────────────────────────────┐
│                   SEAL ACQUISITION                         │
│                                                            │
│  🎉 Chapter Complete!                                      │
│                                                            │
│  New Seal Acquired: 📖                                     │
│  ┌────────────────────────────────────┐                   │
│  │  "Algebra Fundamentals"            │                   │
│  │                                     │                   │
│  │  Primary Seal (主魂印)              │                   │
│  │  - Linear equation solving          │                   │
│  │  - Variable manipulation            │                   │
│  │  - +10% Math Power                  │                   │
│  └────────────────────────────────────┘                   │
│                                                            │
│  Seal added to inventory                                  │
│  Can equip and use in future battles                      │
└────────────────────────────────────────────────────────────┘
```

## Resource Progression

```
Game Start → Phase 2 Complete
═══════════════════════════════════════════════════════════

Question Types:
├─ Start:  [Multiple Choice Only]
└─ End:    [Multiple Choice, Fill-in-Blank, Equations, 
            Expression Simplification, Multi-Step]

Combat Mechanics:
├─ Start:  [Generic Weapon Attacks]
└─ End:    [Knowledge Pen (点墨/挥毫) + Ink Energy + 
            Knowledge Lock + Finishing Moves]

Progression System:
├─ Start:  [XP Levels]
└─ End:    [Book-Soul Seals (书魂印) representing mastered 
            knowledge domains]

Content:
├─ Start:  [Biology Questions (Legacy)]
└─ End:    [Math Curriculum (Grades 1-12, 100+ questions)]

Evaluation:
├─ Start:  [Simple String Match]
└─ End:    [Python + SymPy Symbolic Math Engine]
```

## Feature Dependencies

```
                    ┌──────────────────────┐
                    │ Evaluation Engine    │
                    │ (Foundation)         │
                    └──────────┬───────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         │                     │                     │
         ▼                     ▼                     ▼
┌────────────────┐  ┌───────────────────┐  ┌───────────────┐
│ Enhanced       │  │ Knowledge Pen &   │  │ Book-Soul     │
│ Questions      │  │ Ink Energy        │  │ Seals         │
│                │  │                   │  │               │
│ Requires:      │  │ Requires:         │  │ Requires:     │
│ - Evaluation   │  │ - Combat System   │  │ - Quest System│
│   Engine       │  │ - UI System       │  │ - Inventory   │
└────────────────┘  └───────────────────┘  └───────────────┘
         │                     │                     │
         └─────────────────────┼─────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Complete Knowledge-  │
                    │ Combat Integration   │
                    │ (Phase 2 Goal)       │
                    └──────────────────────┘
```

## Success Metrics Dashboard

```
Phase 2 Completion Criteria:
════════════════════════════════════════════════════════════

Technical Metrics:
┌────────────────────────────────────────────┬──────────────┐
│ Evaluation Latency                         │ <100ms ✓     │
│ Evaluation Accuracy                        │ 99%+ ✓       │
│ Knowledge Lock Input Lag                   │ <2 frames ✓  │
│ Supported Seals                            │ 20+ ✓        │
│ Evaluation Methods                         │ 5+ ✓         │
└────────────────────────────────────────────┴──────────────┘

Gameplay Metrics:
┌────────────────────────────────────────────┬──────────────┐
│ Battle-Quiz Completion Rate               │ >70% ✓       │
│ Average Engagement Time                    │ >5 min ✓     │
│ First-Attempt Correct Rate                 │ 40-60% ✓     │
│ Seals per Hour                             │ 3+ ✓         │
└────────────────────────────────────────────┴──────────────┘

Educational Metrics:
┌────────────────────────────────────────────┬──────────────┐
│ Math Topics Covered                        │ 10+ ✓        │
│ Clear Difficulty Progression               │ Yes ✓        │
│ Hint Usage Rate                            │ <30% ✓       │
│ Retention on Similar Questions             │ 80%+ ✓       │
└────────────────────────────────────────────┴──────────────┘

Content Metrics:
┌────────────────────────────────────────────┬──────────────┐
│ Total Questions                            │ 100+ ✓       │
│ Question Types                             │ 5+ ✓         │
│ Math Grade Coverage                        │ 1-12 ✓       │
│ Seals Implemented                          │ 10+ ✓        │
└────────────────────────────────────────────┴──────────────┘
```

## Risk Heat Map

```
Impact vs Probability Matrix:
═════════════════════════════════════════════════════════

High Impact │
           │  [Python        [Ink Energy
           │   Integration]   Balancing]
           │      🔴             🟡
           │
           │  [Seal System   [Content
Medium     │   Complexity]    Creation]
Impact     │      🟡             🟢
           │
           │  [UI Polish]    [Performance]
Low Impact │      🟢             🟢
           │
           └─────────────────────────────────▶
              Low         Medium        High
                    Probability

🔴 High Risk  - Needs mitigation plan
🟡 Medium Risk - Monitor closely
🟢 Low Risk   - Standard process
```

## Phase Transition

```
┌──────────────────────────────────────────────────────────┐
│  Phase 1: Core Architecture (Complete) ✅                │
│  - Foundation systems                                    │
│  - Battle-quiz prototype                                 │
│  - Component architecture                                │
└────────────────────┬─────────────────────────────────────┘
                     │
                     │ YOU ARE HERE
                     ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 2: Knowledge-Combat Integration (Predicted) 🎯   │
│  - Offline evaluation engine                             │
│  - Knowledge pen mechanics                               │
│  - Book-soul seal system                                 │
│  - Math content migration                                │
└────────────────────┬─────────────────────────────────────┘
                     │
                     │ After 10-12 Weeks
                     ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 3: Advanced Learning Systems (Future) 🔮          │
│  - Skill tree (百川归海)                                  │
│  - Enlightenment trials (顿悟三阶试炼)                     │
│  - PBL projects (天问)                                    │
│  - Multi-subject expansion                                │
└──────────────────────────────────────────────────────────┘
```

---

This visual roadmap provides a clear picture of:
- Where the project is now
- What needs to be built
- How components fit together
- Timeline and dependencies
- Success criteria
- Risk assessment
