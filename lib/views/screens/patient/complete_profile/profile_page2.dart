import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/bottom_navigation_patient.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io';

class CompleteProfilePatient2Screen extends StatefulWidget {
  const CompleteProfilePatient2Screen({super.key});

  @override
  State<CompleteProfilePatient2Screen> createState() => _CompleteProfilePatient2ScreenState();
}

class _CompleteProfilePatient2ScreenState extends State<CompleteProfilePatient2Screen> {
  File? _medicalReport1;
  File? _medicalReport2;
  final ImagePicker _picker = ImagePicker();

  String? selectedBloodGroup;
  List<String> selectedDiseases = [];
  List<String> selectedAllergies = [];
  String searchQuery = '';
  String allergySearchQuery = '';
  
  final List<String> bloodGroups = ["A-", "A+", "B-", "B+", "AB", "AB-"];
  
  // Grouped diseases
  final Map<String, List<String>> groupedDiseases = {
    "Chronic Diseases": [
      "Diabetes",
      "Hypertension",
      "High Blood Pressure",
      "Arthritis",
      "Asthma",
      "Kidney Problem",
      "Heart Issue",
      "Thyroid Disorder",
      "Liver Disease",
      "Cancer",
      "Tuberculosis",
      "Epilepsy",
      "Chronic Obstructive Pulmonary Disease (COPD)",
      "HIV/AIDS",
      "Chronic Fatigue Syndrome",
      "Fibromyalgia",
      "Chronic Pain",
      "Chronic Kidney Disease",
      "Chronic Liver Disease",
      "Chronic Heart Failure",
      "Bronchiectasis",
      "Pulmonary Fibrosis",
      "Interstitial Lung Disease",
      "Peripheral Vascular Disease",
      "Coronary Artery Disease",
      "Atrial Fibrillation",
      "Congestive Heart Failure",
      "Arrhythmia",
      "Cardiomyopathy",
    ],
    "Mental Health": [
      "Depression",
      "Anxiety",
      "Alzheimer's Disease",
      "Parkinson's Disease",
      "Bipolar Disorder",
      "Schizophrenia",
      "Post-Traumatic Stress Disorder (PTSD)",
      "Obsessive-Compulsive Disorder (OCD)",
      "Attention Deficit Hyperactivity Disorder (ADHD)",
      "Autism Spectrum Disorder",
      "Eating Disorders",
      "Substance Abuse",
      "Insomnia",
      "Generalized Anxiety Disorder",
      "Social Anxiety Disorder",
      "Panic Disorder",
      "Agoraphobia",
      "Seasonal Affective Disorder",
      "Dissociative Identity Disorder",
      "Borderline Personality Disorder",
      "Narcissistic Personality Disorder",
      "Antisocial Personality Disorder",
      "Bulimia Nervosa",
      "Anorexia Nervosa",
      "Binge Eating Disorder",
      "Gaming Disorder",
    ],
    "Autoimmune Disorders": [
      "Multiple Sclerosis",
      "Psoriasis",
      "Celiac Disease",
      "Rheumatoid Arthritis",
      "Lupus",
      "Type 1 Diabetes",
      "Inflammatory Bowel Disease",
      "Graves' Disease",
      "Hashimoto's Thyroiditis",
      "Sjögren's Syndrome",
      "Myasthenia Gravis",
      "Vasculitis",
      "Addison's Disease",
      "Ankylosing Spondylitis",
      "Scleroderma",
      "Guillain-Barré Syndrome",
      "Polymyalgia Rheumatica",
      "Reactive Arthritis",
      "Behçet's Disease",
      "Giant Cell Arteritis",
      "Polymyositis",
      "Dermatomyositis",
      "Pernicious Anemia",
      "Vitiligo",
      "Alopecia Areata",
    ],
    "Digestive Disorders": [
      "Gastroesophageal Reflux Disease (GERD)",
      "Irritable Bowel Syndrome (IBS)",
      "Crohn's Disease",
      "Ulcerative Colitis",
      "Gastritis",
      "Peptic Ulcer",
      "Gallstones",
      "Diverticulitis",
      "Constipation",
      "Diarrhea",
      "Food Poisoning",
      "Gastroenteritis",
      "Hemorrhoids",
      "Celiac Disease",
      "Fatty Liver Disease",
      "Pancreatitis",
      "Cirrhosis",
      "Hiatal Hernia",
      "Esophagitis",
      "Barrett's Esophagus",
      "Gastroparesis",
      "Small Intestinal Bacterial Overgrowth (SIBO)",
      "Malabsorption Syndrome",
      "Lactose Intolerance",
      "Fructose Intolerance",
      "Whipple's Disease",
      "Diverticulosis",
      "Anal Fissure",
      "Rectal Prolapse",
    ],
    "Reproductive Health": [
      "Polycystic Ovary Syndrome (PCOS)",
      "Endometriosis",
      "Infertility",
      "Menstrual Disorders",
      "Premenstrual Syndrome (PMS)",
      "Uterine Fibroids",
      "Ovarian Cysts",
      "Sexually Transmitted Infections (STIs)",
      "Erectile Dysfunction",
      "Prostate Problems",
      "Premature Ejaculation",
      "Testicular Cancer",
      "Ovarian Cancer",
      "Cervical Cancer",
      "Uterine Cancer",
      "Vulvodynia",
      "Vaginismus",
      "Dyspareunia",
      "Premenstrual Dysphoric Disorder (PMDD)",
      "Amenorrhea",
      "Dysmenorrhea",
      "Menopause",
      "Andropause",
      "Genital Herpes",
      "Human Papillomavirus (HPV)",
      "Chlamydia",
      "Gonorrhea",
      "Syphilis",
      "Trichomoniasis",
      "Bacterial Vaginosis",
      "Pelvic Inflammatory Disease",
      "Ectopic Pregnancy",
      "Varicocele",
      "Hydrocele",
    ],
    "Blood Disorders": [
      "Anemia",
      "Leukemia",
      "Lymphoma",
      "Sickle Cell Disease",
      "Hemophilia",
      "Thalassemia",
      "Deep Vein Thrombosis (DVT)",
      "Hemochromatosis",
      "Thrombocytopenia",
      "Polycythemia Vera",
      "Aplastic Anemia",
      "Multiple Myeloma",
      "Von Willebrand Disease",
      "Factor V Leiden",
      "Protein C Deficiency",
      "Protein S Deficiency",
      "Antithrombin Deficiency",
      "Spherocytosis",
      "Porphyria",
      "G6PD Deficiency",
      "Platelet Function Disorders",
      "Myelofibrosis",
      "Myelodysplastic Syndromes",
      "Essential Thrombocythemia",
      "Disseminated Intravascular Coagulation",
    ],
    "Respiratory Conditions": [
      "Asthma",
      "Chronic Obstructive Pulmonary Disease (COPD)",
      "Pneumonia",
      "Bronchitis",
      "Sinusitis",
      "Common Cold",
      "Influenza (Flu)",
      "Tuberculosis",
      "Lung Cancer",
      "Cystic Fibrosis",
      "Pulmonary Embolism",
      "Pleural Effusion",
      "Pneumothorax",
      "Sarcoidosis",
      "Sleep Apnea",
      "Allergic Rhinitis",
      "Hay Fever",
      "Emphysema",
      "Pulmonary Hypertension",
      "Bronchiectasis",
      "Pulmonary Fibrosis",
      "Legionnaires' Disease",
      "Whooping Cough",
      "Respiratory Syncytial Virus (RSV)",
      "Pleurisy",
      "Acute Respiratory Distress Syndrome (ARDS)",
      "Hypersensitivity Pneumonitis",
    ],
    "Neurological Disorders": [
      "Epilepsy",
      "Multiple Sclerosis",
      "Parkinson's Disease",
      "Alzheimer's Disease",
      "Migraine",
      "Stroke",
      "Brain Tumor",
      "Meningitis",
      "Encephalitis",
      "Guillain-Barré Syndrome",
      "Myasthenia Gravis",
      "Huntington's Disease",
      "Amyotrophic Lateral Sclerosis (ALS)",
      "Peripheral Neuropathy",
      "Bell's Palsy",
      "Trigeminal Neuralgia",
      "Cluster Headache",
      "Tension Headache",
      "Narcolepsy",
      "Restless Legs Syndrome",
      "Essential Tremor",
      "Tourette Syndrome",
      "Cerebral Palsy",
      "Transient Ischemic Attack (TIA)",
      "Spina Bifida",
      "Hydrocephalus",
      "Chiari Malformation",
      "Syringomyelia",
      "Pseudotumor Cerebri",
      "Progressive Supranuclear Palsy",
      "Dystonia",
    ],
    "Infectious Diseases": [
      "Hepatitis B",
      "Hepatitis C",
      "Dengue",
      "Malaria",
      "Chikungunya",
      "COVID-19",
      "Pneumonia",
      "Bronchitis",
      "Sinusitis",
      "Tonsillitis",
      "Tuberculosis",
      "Influenza (Flu)",
      "Common Cold",
      "Chickenpox",
      "Measles",
      "Mumps",
      "Rubella",
      "Whooping Cough",
      "Tetanus",
      "Diphtheria",
      "Polio",
      "Typhoid",
      "Cholera",
      "Dysentery",
      "Scabies",
      "Ringworm",
      "Lyme Disease",
      "Zika Virus",
      "Yellow Fever",
      "Rabies",
      "HIV/AIDS",
      "Ebola",
      "MERS",
      "SARS",
      "West Nile Virus",
      "Hantavirus",
      "Herpes Simplex",
      "Herpes Zoster (Shingles)",
      "Cytomegalovirus",
      "Epstein-Barr Virus (Mononucleosis)",
      "Hand, Foot, and Mouth Disease",
      "Fifth Disease",
      "Roseola",
      "Scarlet Fever",
      "Leishmaniasis",
      "Chagas Disease",
      "Plague",
      "Anthrax",
      "Rocky Mountain Spotted Fever",
      "Q Fever",
      "Listeriosis",
      "Brucellosis",
      "Botulism",
      "Trichinosis",
    ],
    "Common Illnesses": [
      "Fever",
      "Headache",
      "Common Cold",
      "Cough",
      "Sore Throat",
      "Runny Nose",
      "Sinus Infection",
      "Ear Infection",
      "Eye Infection",
      "Urinary Tract Infection (UTI)",
      "Skin Infection",
      "Food Poisoning",
      "Stomach Flu",
      "Motion Sickness",
      "Allergic Reaction",
      "Sunburn",
      "Dehydration",
      "Heat Stroke",
      "Hypothermia",
      "Sprains",
      "Bruises",
      "Cuts",
      "Burns",
      "Indigestion",
      "Acid Reflux",
      "Nausea",
      "Vomiting",
      "Dizziness",
      "Fatigue",
      "Insomnia",
      "Constipation",
      "Diarrhea",
      "Abdominal Pain",
      "Muscle Aches",
      "Joint Pain",
      "Back Pain",
      "Neck Pain",
      "Toothache",
      "Gum Infection",
      "Laryngitis",
      "Stye",
      "Conjunctivitis (Pink Eye)",
      "Boils",
      "Thrush",
      "Athlete's Foot",
      "Jock Itch",
      "Dandruff",
      "Nail Fungus",
      "Hives",
      "Rash",
    ],
    "Pediatric Conditions": [
      "ADHD",
      "Autism Spectrum Disorder",
      "Chickenpox",
      "Measles",
      "Mumps",
      "Whooping Cough",
      "Croup",
      "Respiratory Syncytial Virus (RSV)",
      "Hand, Foot, and Mouth Disease",
      "Fifth Disease",
      "Roseola",
      "Scarlet Fever",
      "Ear Infection",
      "Strep Throat",
      "Growth Disorders",
      "Juvenile Idiopathic Arthritis",
      "Kawasaki Disease",
      "Tetralogy of Fallot",
      "Ventricular Septal Defect",
      "Atrial Septal Defect",
      "Patent Ductus Arteriosus",
      "Down Syndrome",
      "Fragile X Syndrome",
      "Cerebral Palsy",
      "Congenital Hip Dysplasia",
      "Cleft Lip/Palate",
      "Club Foot",
      "Pyloric Stenosis",
      "Intussusception",
      "Hirschsprung's Disease",
      "Developmental Delays",
      "Learning Disabilities",
      "Nephrotic Syndrome",
      "Henoch-Schönlein Purpura",
      "Reye's Syndrome",
      "Neonatal Jaundice",
      "Sudden Infant Death Syndrome (SIDS)",
    ],
    "Geriatric Conditions": [
      "Alzheimer's Disease",
      "Dementia",
      "Parkinson's Disease",
      "Osteoporosis",
      "Osteoarthritis",
      "Age-related Macular Degeneration",
      "Cataracts",
      "Glaucoma",
      "Hearing Loss",
      "Presbycusis",
      "Falls and Frailty",
      "Urinary Incontinence",
      "Fecal Incontinence",
      "Pressure Ulcers",
      "Malnutrition in Elderly",
      "Sarcopenia",
      "Elder Abuse",
      "Polypharmacy",
      "Benign Prostatic Hyperplasia",
      "Diverticular Disease",
      "Giant Cell Arteritis",
      "Polymyalgia Rheumatica",
      "Orthostatic Hypotension",
      "Peripheral Arterial Disease",
      "Senile Purpura",
      "Normal Pressure Hydrocephalus",
    ],
    "Skin Conditions": [
      "Acne",
      "Eczema",
      "Psoriasis",
      "Rosacea",
      "Dermatitis",
      "Hives",
      "Vitiligo",
      "Melanoma",
      "Basal Cell Carcinoma",
      "Squamous Cell Carcinoma",
      "Shingles",
      "Cellulitis",
      "Impetigo",
      "Folliculitis",
      "Boils",
      "Carbuncles",
      "Hidradenitis Suppurativa",
      "Scabies",
      "Ringworm",
      "Athlete's Foot",
      "Jock Itch",
      "Dandruff",
      "Seborrheic Dermatitis",
      "Cold Sores",
      "Warts",
      "Moles",
      "Skin Tags",
      "Keloids",
      "Scleroderma",
      "Lupus of the Skin",
      "Pemphigus",
      "Bullous Pemphigoid",
      "Lichen Planus",
      "Pityriasis Rosea",
      "Sebaceous Cyst",
    ],
    "Eye Disorders": [
      "Cataracts",
      "Glaucoma",
      "Age-related Macular Degeneration",
      "Diabetic Retinopathy",
      "Retinal Detachment",
      "Dry Eye Syndrome",
      "Conjunctivitis (Pink Eye)",
      "Stye",
      "Chalazion",
      "Blepharitis",
      "Keratitis",
      "Uveitis",
      "Corneal Ulcer",
      "Pterygium",
      "Floaters",
      "Amblyopia (Lazy Eye)",
      "Strabismus (Crossed Eyes)",
      "Color Blindness",
      "Nystagmus",
      "Optic Neuritis",
      "Retinitis Pigmentosa",
    ],
    "Other Conditions": [
      "Migraine",
      "Obesity",
      "Allergies",
      "Stroke",
      "Gallbladder Disease",
      "Eczema",
      "Sleep Apnea",
      "Osteoporosis",
      "Osteoarthritis",
      "Gout",
      "Cataracts",
      "Glaucoma",
      "Macular Degeneration",
      "Hearing Loss",
      "Tinnitus",
      "Vertigo",
      "Dental Problems",
      "Gum Disease",
      "Back Pain",
      "Neck Pain",
      "Joint Pain",
      "Muscle Pain",
      "Nerve Pain",
      "Skin Conditions",
      "Hair Loss",
      "Nail Problems",
      "Foot Problems",
      "Hand Problems",
      "Spinal Problems",
      "Bone Fractures",
      "Chronic Sinusitis",
      "Mastoiditis",
      "Labyrinthitis",
      "Ménière's Disease",
      "Raynaud's Phenomenon",
      "Temporomandibular Joint Disorder (TMJ)",
      "Geographic Tongue",
      "Burning Mouth Syndrome",
      "Benign Positional Vertigo",
      "Cushing's Syndrome",
      "Addison's Disease",
      "Graves' Disease",
      "Hypothyroidism",
      "Hyperthyroidism",
      "Goiter",
      "Hyperparathyroidism",
      "Hypoparathyroidism",
      "Carpal Tunnel Syndrome",
      "Dupuytren's Contracture",
      "Trigger Finger",
      "Ganglion Cyst",
      "Bunion",
      "Plantar Fasciitis",
      "Achilles Tendonitis",
      "Hammer Toe",
    ],
  };

  // Grouped allergies
  final Map<String, List<String>> groupedAllergies = {
    "Food Allergies": [
      "Peanuts",
      "Tree Nuts",
      "Milk",
      "Eggs",
      "Fish",
      "Shellfish",
      "Soy",
      "Wheat",
      "Sesame",
      "Mustard",
      "Celery",
      "Lupin",
      "Molluscs",
      "Sulphites",
      "Gluten",
    ],
    "Medication Allergies": [
      "Penicillin",
      "Sulfa Drugs",
      "Aspirin",
      "Ibuprofen",
      "Naproxen",
      "Codeine",
      "Morphine",
      "Local Anesthetics",
      "Insulin",
      "Vaccines",
      "Antibiotics",
      "Anticonvulsants",
      "Chemotherapy Drugs",
      "ACE Inhibitors",
      "Statins",
    ],
    "Environmental Allergies": [
      "Pollen",
      "Dust Mites",
      "Mold",
      "Pet Dander",
      "Cockroach Allergens",
      "Grass",
      "Weed Pollen",
      "Tree Pollen",
      "Ragweed",
      "Hay Fever",
      "Smoke",
      "Perfumes",
      "Cleaning Products",
      "Latex",
      "Insect Stings",
    ],
    "Skin Allergies": [
      "Nickel",
      "Fragrances",
      "Preservatives",
      "Rubber",
      "Hair Dye",
      "Cosmetics",
      "Sunscreen",
      "Adhesives",
      "Topical Medications",
      "Essential Oils",
      "Wool",
      "Detergents",
      "Soaps",
      "Shampoos",
      "Fabric Softeners",
    ],
    "Other Allergies": [
      "Bee Stings",
      "Wasp Stings",
      "Fire Ant Stings",
      "Mosquito Bites",
      "Ticks",
      "Mites",
      "Flea Bites",
      "Contact Lenses",
      "Dental Materials",
      "Surgical Implants",
      "Tattoo Ink",
      "Henna",
      "Hair Products",
      "Nail Products",
      "Jewelry",
    ],
  };

  // Get all diseases as a flat list
  List<String> get allDiseases {
    List<String> result = [];
    groupedDiseases.forEach((key, value) {
      result.addAll(value);
    });
    return result;
  }

  // Get filtered diseases based on search query
  List<MapEntry<String, List<String>>> get filteredGroupedDiseases {
    if (searchQuery.isEmpty) {
      return groupedDiseases.entries.toList();
    }
    
    Map<String, List<String>> filteredGroups = {};
    
    groupedDiseases.forEach((group, diseases) {
      List<String> filtered = diseases.where((disease) => 
        disease.toLowerCase().contains(searchQuery.toLowerCase())).toList();
      
      if (filtered.isNotEmpty) {
        filteredGroups[group] = filtered;
      }
    });
    
    return filteredGroups.entries.toList();
  }

  // Get filtered allergies based on search query
  List<MapEntry<String, List<String>>> get filteredGroupedAllergies {
    if (allergySearchQuery.isEmpty) {
      return groupedAllergies.entries.toList();
    }
    
    Map<String, List<String>> filteredGroups = {};
    
    groupedAllergies.forEach((group, allergies) {
      List<String> filtered = allergies.where((allergy) => 
        allergy.toLowerCase().contains(allergySearchQuery.toLowerCase())).toList();
      
      if (filtered.isNotEmpty) {
        filteredGroups[group] = filtered;
      }
    });
    
    return filteredGroups.entries.toList();
  }

  Future<void> _pickFile(bool isFirstReport) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isFirstReport) {
          _medicalReport1 = File(pickedFile.path);
        } else {
          _medicalReport2 = File(pickedFile.path);
        }
      });
    }
  }

  Widget _buildDropdown({required String hint, required List<String> items, required String? value, required void Function(String?) onChanged}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3366CC).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: value == null ? Colors.grey.shade300 : const Color(0xFF3366CC).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3366CC).withOpacity(0.1),
                  const Color(0xFF3366CC).withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Icon(
              LucideIcons.droplet,
              color: const Color(0xFF3366CC),
              size: 20,
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    hint,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: value == item ? const Color(0xFF3366CC).withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: value == item ? const Color(0xFF3366CC) : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: value == item ? const Color(0xFF3366CC) : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: value == item
                                ? const Icon(
                                    LucideIcons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item,
                            style: GoogleFonts.poppins(
                              color: value == item ? const Color(0xFF3366CC) : Colors.black87,
                              fontSize: 14,
                              fontWeight: value == item ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
                icon: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    LucideIcons.chevronDown,
                    color: const Color(0xFF3366CC),
                  ),
                ),
                dropdownColor: Colors.white,
                menuMaxHeight: 300,
                borderRadius: BorderRadius.circular(16),
                elevation: 4,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableDiseaseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search box with enhanced styling
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3366CC).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF3366CC).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3366CC).withOpacity(0.1),
                      const Color(0xFF3366CC).withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.search,
                  color: const Color(0xFF3366CC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search diseases...",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      LucideIcons.x,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Display selected diseases with improved chip styling
        if (selectedDiseases.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xFF3366CC).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3366CC).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3366CC).withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.check,
                      color: const Color(0xFF3366CC),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Selected Diseases",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (selectedDiseases.length > 1)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDiseases.clear();
                          });
                        },
                        child: Text(
                          "Clear All",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF3366CC),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: selectedDiseases.map((disease) {
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3366CC).withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Chip(
                        label: Text(
                          disease,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: const Color(0xFF3366CC),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        deleteIconColor: Colors.white.withOpacity(0.9),
                        deleteIcon: const Icon(LucideIcons.x, size: 14),
                        onDeleted: () {
                          setState(() {
                            selectedDiseases.remove(disease);
                          });
                        },
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        
        // Enhanced disease groups list
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3366CC).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          constraints: const BoxConstraints(maxHeight: 320),
          child: filteredGroupedDiseases.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.search,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No diseases found",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try a different search term",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredGroupedDiseases.length,
                  itemBuilder: (context, groupIndex) {
                    final group = filteredGroupedDiseases[groupIndex];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3366CC).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCategoryIcon(group.key),
                              color: const Color(0xFF3366CC),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            group.key,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            "${group.value.length} ${group.value.length == 1 ? 'disease' : 'diseases'}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Icon(
                            LucideIcons.chevronDown,
                            color: const Color(0xFF3366CC),
                            size: 20,
                          ),
                          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: group.value.length,
                              itemBuilder: (context, index) {
                                final disease = group.value[index];
                                final isSelected = selectedDiseases.contains(disease);
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedDiseases.remove(disease);
                                      } else {
                                        selectedDiseases.add(disease);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF3366CC)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF3366CC)
                                                  : Colors.grey.shade400,
                                              width: 1.5,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF3366CC).withOpacity(0.2),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  LucideIcons.check,
                                                  color: Colors.white,
                                                  size: 16,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            disease,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                              color: isSelected ? const Color(0xFF3366CC) : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Helper method to get an appropriate icon for each disease category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Chronic Diseases":
        return LucideIcons.activity;
      case "Mental Health":
        return LucideIcons.brain;
      case "Autoimmune Disorders":
        return LucideIcons.shieldAlert;
      case "Digestive Disorders":
        return LucideIcons.heartPulse;
      case "Reproductive Health":
        return LucideIcons.baby;
      case "Blood Disorders":
        return LucideIcons.droplets;
      case "Respiratory Conditions":
        return LucideIcons.wind;
      case "Neurological Disorders":
        return LucideIcons.network;
      case "Infectious Diseases":
        return LucideIcons.bug;
      case "Common Illnesses":
        return LucideIcons.thermometer;
      case "Pediatric Conditions":
        return LucideIcons.users;
      case "Geriatric Conditions":
        return LucideIcons.user;
      case "Skin Conditions":
        return LucideIcons.scan;
      case "Eye Disorders":
        return LucideIcons.eye;
      default:
        return LucideIcons.plus;
    }
  }

  Widget _buildSearchableAllergySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search box with enhanced styling
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3366CC).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF3366CC).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3366CC).withOpacity(0.1),
                      const Color(0xFF3366CC).withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.search,
                  color: const Color(0xFF3366CC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      allergySearchQuery = value;
                    });
                  },
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search allergies...",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (allergySearchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      allergySearchQuery = '';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      LucideIcons.x,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Display selected allergies with improved chip styling
        if (selectedAllergies.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xFF3366CC).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3366CC).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3366CC).withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.check,
                      color: const Color(0xFF3366CC),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Selected Allergies",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (selectedAllergies.length > 1)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAllergies.clear();
                          });
                        },
                        child: Text(
                          "Clear All",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF3366CC),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: selectedAllergies.map((allergy) {
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3366CC).withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Chip(
                        label: Text(
                          allergy,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: const Color(0xFF3366CC),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        deleteIconColor: Colors.white.withOpacity(0.9),
                        deleteIcon: const Icon(LucideIcons.x, size: 14),
                        onDeleted: () {
                          setState(() {
                            selectedAllergies.remove(allergy);
                          });
                        },
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        
        // Enhanced allergy groups list
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3366CC).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          constraints: const BoxConstraints(maxHeight: 320),
          child: filteredGroupedAllergies.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.search,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No allergies found",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try a different search term",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredGroupedAllergies.length,
                  itemBuilder: (context, groupIndex) {
                    final group = filteredGroupedAllergies[groupIndex];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3366CC).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getAllergyCategoryIcon(group.key),
                              color: const Color(0xFF3366CC),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            group.key,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            "${group.value.length} ${group.value.length == 1 ? 'allergy' : 'allergies'}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Icon(
                            LucideIcons.chevronDown,
                            color: const Color(0xFF3366CC),
                            size: 20,
                          ),
                          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: group.value.length,
                              itemBuilder: (context, index) {
                                final allergy = group.value[index];
                                final isSelected = selectedAllergies.contains(allergy);
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedAllergies.remove(allergy);
                                      } else {
                                        selectedAllergies.add(allergy);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF3366CC)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF3366CC)
                                                  : Colors.grey.shade400,
                                              width: 1.5,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF3366CC).withOpacity(0.2),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  LucideIcons.check,
                                                  color: Colors.white,
                                                  size: 16,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            allergy,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                              color: isSelected ? const Color(0xFF3366CC) : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Helper method to get an appropriate icon for each allergy category
  IconData _getAllergyCategoryIcon(String category) {
    switch (category) {
      case "Food Allergies":
        return LucideIcons.utensils;
      case "Medication Allergies":
        return LucideIcons.pill;
      case "Environmental Allergies":
        return LucideIcons.wind;
      case "Skin Allergies":
        return LucideIcons.scan;
      case "Other Allergies":
        return LucideIcons.plus;
      default:
        return LucideIcons.plus;
    }
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3366CC).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: const Color(0xFF3366CC),
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildUploadBox({required String label, required bool isFirstReport}) {
    return GestureDetector(
      onTap: () => _pickFile(isFirstReport),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3366CC).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: (isFirstReport ? _medicalReport1 : _medicalReport2) == null 
                ? Colors.grey.shade300 
                : const Color(0xFF3366CC).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3366CC).withOpacity(0.1),
                    const Color(0xFF3366CC).withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.fileText,
                color: const Color(0xFF3366CC),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ".pdf, .png, .jpg, .jpeg (Max: 5MB)",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3366CC).withOpacity(0.1),
                    const Color(0xFF3366CC).withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                (isFirstReport ? _medicalReport1 : _medicalReport2) == null
                    ? LucideIcons.upload
                    : LucideIcons.check,
                color: const Color(0xFF3366CC),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Complete Your Profile",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF3366CC)),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F8FF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3366CC).withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3366CC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.stethoscope,
                            color: const Color(0xFF3366CC),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Medical Information",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      hint: "Select Blood Group",
                      items: bloodGroups,
                      value: selectedBloodGroup,
                      onChanged: (value) {
                        setState(() {
                          selectedBloodGroup = value;
                        });
                      },
                    ),
                    _buildTextField(
                      hint: "Disability (If Any)",
                      icon: LucideIcons.userCog,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Select Diseases",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 8),
                    _buildSearchableDiseaseSelector(),
                    const SizedBox(height: 8),
                    Text(
                      "Select Allergies",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 8),
                    _buildSearchableAllergySelector(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3366CC).withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3366CC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.fileText,
                            color: const Color(0xFF3366CC),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Medical Reports",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildUploadBox(label: "Medical Report 1", isFirstReport: true),
                    _buildUploadBox(label: "Medical Report 2", isFirstReport: false),
                    _buildTextField(
                      hint: "Additional Notes",
                      icon: LucideIcons.fileText,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3366CC).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => popUpSuccess(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3366CC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Complete Profile",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.check, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void popUpSuccess(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      Timer(
        const Duration(seconds: 3),
        () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BottomNavigationBarPatientScreen(
              profileStatus: "complete"
            ),
          ),
        ),
      );

      return Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: const Color.fromARGB(30, 0, 0, 0),
            ),
          ),
          AlertDialog(
            backgroundColor: const Color(0xFF3366CC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Profile Completed Successfully",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
