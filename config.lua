Config = {}

Config.Items = {
    water_bottle = {label = "Water Bottle", buyPrice = 5, sellPrice = 2},
    tosti = {label = "Tosti", buyPrice = 3, sellPrice = 1},
    --Add More Items here
}

Config.NPC = {
    model = 'mp_m_shopkeep_01', --NPC Model
    coords = vector3(2746.78, 3471.83, 54.67), --Location for NPC and Blips
    heading = 258.75,
    blip = { --Add Your Blips
        sprite = 293,
        color = 2,
        scale = 0.8,
        text = "Shop"
    }
}
