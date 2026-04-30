# frozen_string_literal: true

# Seed initial structure for EEDS (Éclaireurs et Éclaireuses du Sénégal).
# Idempotent: safe to run multiple times — uses seed_once / find_or_create_by.
#
# Run with:
#   docker compose exec rails bundle exec rails runner -e <env> \
#     /usr/src/app/hitobito_pbs/db/seeds/eeds_structure.rb

puts "→ Seeding EEDS structure…"

# ---------------------------------------------------------------------------
# 1. Root + Bund (National)
# ---------------------------------------------------------------------------
root = Group::Root.first || Group::Root.seed_once(:parent_id, { name: "Root" }).first

bund = Group::Bund.first
if bund
  bund.update_columns(name: "EEDS", short_name: "EEDS") unless bund.name == "EEDS"
else
  bund = Group::Bund.create!(
    name: "EEDS",
    short_name: "EEDS",
    parent_id: root.id,
    country: "SN",
    town: "Dakar"
  )
end
puts "  Bund: #{bund.name} (id=#{bund.id})"

# ---------------------------------------------------------------------------
# 2. Entités gestionnaires nationales (sous Bund)
#    - Comité Directeur          → Group::BundesGremium
#    - Équipe Nationale          → Group::BundesGremium
#    - Commission Formation       → Group::Ausbildungskommission
# ---------------------------------------------------------------------------
national_entities = [
  { klass: Group::BundesGremium,        name: "Comité Directeur" },
  { klass: Group::BundesGremium,        name: "Équipe Nationale" },
  { klass: Group::Ausbildungskommission, name: "Commission Formation" }
]

national_entities.each do |entry|
  g = entry[:klass].find_or_create_by!(name: entry[:name], parent_id: bund.id) do |grp|
    grp.country = "SN"
    grp.town = "Dakar"
    grp.language = "fr"
  end
  puts "  ↳ #{entry[:klass].label}: #{g.name} (id=#{g.id})"
end

# ---------------------------------------------------------------------------
# 3. Régions (sous Bund)
# ---------------------------------------------------------------------------
regions_data = [
  { name: "Région de Dakar",      short_name: "DKR", town: "Dakar" },
  { name: "Région de Thiès",      short_name: "THS", town: "Thiès" },
  { name: "Région de Ziguinchor", short_name: "ZGR", town: "Ziguinchor" }
]

regions = {}
regions_data.each do |r|
  reg = Group::Kantonalverband.find_or_create_by!(name: r[:name], parent_id: bund.id) do |g|
    g.short_name = r[:short_name]
    g.country    = "SN"
    g.town       = r[:town]
    g.language   = "fr"
  end
  regions[r[:short_name]] = reg
  puts "  ↳ Région: #{reg.name} (id=#{reg.id})"
end

# ---------------------------------------------------------------------------
# 4. Districts rattachés à une Région
# ---------------------------------------------------------------------------
districts_par_region = {
  "DKR" => [
    { name: "District Front de Terre",     town: "Dakar" },
    { name: "District Pikine Guédiawaye",  town: "Pikine" },
    { name: "District Rufisque",           town: "Rufisque" }
  ]
}

districts_par_region.each do |region_short, districts|
  parent = regions[region_short]
  districts.each do |d|
    dist = Group::Region.find_or_create_by!(name: d[:name], parent_id: parent.id) do |g|
      g.country = "SN"
      g.town    = d[:town]
      g.language = "fr"
    end
    puts "    ↳ District: #{dist.name} (sous #{parent.short_name}, id=#{dist.id})"
  end
end

# ---------------------------------------------------------------------------
# 5. Districts autonomes (sous Bund directement)
# ---------------------------------------------------------------------------
districts_autonomes = [
  { name: "District Autonome Dioffior-Fimela", town: "Fimela" },
  { name: "District Autonome Diourbel",        town: "Diourbel" },
  { name: "District Autonome Kaolack",         town: "Kaolack" },
  { name: "District Autonome Kolda",           town: "Kolda" },
  { name: "District Autonome Matam",           town: "Matam" },
  { name: "District Autonome Saint-Louis",     town: "Saint-Louis" }
]

districts_autonomes.each do |d|
  dist = Group::Region.find_or_create_by!(name: d[:name], parent_id: bund.id) do |g|
    g.country = "SN"
    g.town    = d[:town]
    g.language = "fr"
  end
  puts "  ↳ District autonome: #{dist.name} (id=#{dist.id})"
end

# ---------------------------------------------------------------------------
# 6. Groupes Locaux Autonomes (sous Bund directement)
# ---------------------------------------------------------------------------
groupes_autonomes = [
  { name: "Groupe Autonome Bakel",        town: "Bakel" },
  { name: "Groupe Autonome Bambey",       town: "Bambey" },
  { name: "Groupe Autonome Dagana",       town: "Dagana" },
  { name: "Groupe Autonome Fadiga",       town: "Fadiga" },
  { name: "Groupe Autonome Gossas",       town: "Gossas" },
  { name: "Groupe Autonome Kaffrine",     town: "Kaffrine" },
  { name: "Groupe Autonome Kebemer",      town: "Kébémer" },
  { name: "Groupe Autonome Niakhar",      town: "Niakhar" },
  { name: "Groupe Autonome Tambacounda",  town: "Tambacounda" }
]

groupes_autonomes.each do |g|
  grp = Group::Abteilung.find_or_create_by!(name: g[:name], parent_id: bund.id) do |gr|
    gr.country = "SN"
    gr.town    = g[:town]
    gr.language = "fr"
  end
  puts "  ↳ Groupe autonome: #{grp.name} (id=#{grp.id})"
end

puts ""
puts "✅ Seed EEDS terminé."
puts "   #{Group.count} groupes en base."
