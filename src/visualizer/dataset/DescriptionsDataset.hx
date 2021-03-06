package visualizer.dataset;

import visualizer.api.APIFacade;


typedef AbilityInfo = {
    var name : String;
    var description : String;
    var effectShort : String;
    var effectLong : String;
    var editorNote: String;
};

typedef ItemInfo = {
    var name : String;
    var description : String;
    var effectShort : String;
    var effectLong : String;
    var flingEffectShort : String;
    var flingEffectLong : String;
    var flingPower: Int;
    var naturalGiftPower : Int;
    var naturalGiftType : String;
};

typedef AbilityMap = Map<String,AbilityInfo>;
typedef TypeEfficacyTable = Map<String,Int>;
typedef ItemMap = Map<String,ItemInfo>;
typedef ItemRenamesMap = Map<String,String>;


class DescriptionsDataset extends Dataset {
    public var abilities(default, null):AbilityMap;
    public var types_efficacy(default, null):TypeEfficacyTable;
    public var items(default, null):ItemMap;
    public var itemRenames(default, null):ItemRenamesMap;
    public var types(default, null):Array<String>;
    var dashlessSlugMap:Map<String,String>;

    public function new() {
        super();
        dashlessSlugMap = new Map<String, String>();
        types = new Array<String>();
    }

    override public function load(callback) {
        makeRequest("descriptions.json", callback);
    }

    override function loadDone(data:Dynamic) {
        abilities = new AbilityMap();
        var abilitiesDoc = Reflect.field(data, "abilities");

        for (slug in Reflect.fields(abilitiesDoc)) {
            var doc = Reflect.field(abilitiesDoc, slug);
            abilities.set(slug, {
                name: Reflect.field(doc, "name"),
                description: Reflect.field(doc, "description"),
                effectShort: Reflect.field(doc, "effect_short"),
                effectLong: Reflect.field(doc, "effect_long"),
                editorNote: Reflect.field(doc, "editor_note")
            });
        }

        types_efficacy = new TypeEfficacyTable();
        var typesDoc = Reflect.field(data, "types_efficacy");

        for (firstType in Reflect.fields(typesDoc)) {
            types.push(firstType);
            var secondTypesDoc = Reflect.field(typesDoc, firstType);

            for (secondType in Reflect.fields(secondTypesDoc)) {
                var efficacy = Reflect.field(secondTypesDoc, secondType);
                types_efficacy.set('$firstType*$secondType', efficacy);
            }
        }

        items = new ItemMap();

        var itemsDoc = Reflect.field(data, "items");

        for (slug in Reflect.fields(itemsDoc)) {
            var doc = Reflect.field(itemsDoc, slug);
            items.set(slug, {
                name: Reflect.field(doc, "name"),
                description: Reflect.field(doc, "description"),
                effectShort: Reflect.field(doc, "effect_short"),
                effectLong: Reflect.field(doc, "effect_long"),
                flingEffectShort: Reflect.field(doc, "fling_effect_short"),
                flingEffectLong: Reflect.field(doc, "fling_effect_long"),
                flingPower: Reflect.field(doc, "fling_power"),
                naturalGiftPower: Reflect.field(doc, "natural_gift_power"),
                naturalGiftType: Reflect.field(doc, "natural_gift_type")
            });
        }

        itemRenames = new ItemRenamesMap();

        var itemRenamesDoc = Reflect.field(data, "item_renames");

        for (oldName in Reflect.fields(itemRenamesDoc)) {
            var newName = Reflect.field(itemRenamesDoc, oldName);

            itemRenames.set(oldName, newName);
        }

        buildDashlessSlugMap();

        super.loadDone(data);
    }

    public function getAbility(slug:String):AbilityInfo {
        if (!abilities.exists(slug)) {
            slug = dashlessSlugMap.get(slug);
        }

        return abilities.get(slug);
    }

    public function getAbilityName(slug:String):String {
        return getAbility(slug).name;
    }

    public function getItem(slug:String):ItemInfo {
        if (items.exists(slug)) {
            return items.get(slug);
        }

        var candidateSlugs = [];

        if (itemRenames.exists(slug)) {
            candidateSlugs.push(itemRenames.get(slug));
        }

        if (dashlessSlugMap.exists(slug)) {
            var dashless = dashlessSlugMap.get(slug);

            candidateSlugs.push(dashless);

            if (itemRenames.exists(dashless)) {
                candidateSlugs.push(itemRenames.get(dashless));
            }
        }

        for (candidate in candidateSlugs) {
            if (items.exists(candidate)) {
                return items.get(candidate);
            }
        }

        return null;
    }

    public function getItemName(slug:String):String {
        return getItem(slug).name;
    }

    public function getTypeEfficacy(user:String, foe:String, ?foeSecondary:String):Int {
        var efficacy:Int = types_efficacy.get('$user*$foe');

        if (foeSecondary == null) {
            return efficacy;
        }

        var secondaryEfficacy:Int = types_efficacy.get('$user*$foeSecondary');

        var pair = [efficacy, secondaryEfficacy];

        return switch (pair) {
            case [0, _]:
                0;
            case [_, 0]:
                0;
            case [200, 200]:
                400;
            case [50, 50]:
                25;
            case [50, 200]:
                100;
            case [200, 50]:
                100;
            case [200, 100]:
                200;
            case [100, 200]:
                200;
            case [50, 100]:
                50;
            case [100, 50]:
                50;
            default:
                100;
        }
    }

    function buildDashlessSlugMap() {
        for (key in items.keys()) {
            dashlessSlugMap.set(APIFacade.slugify(key, true), key);
        }
        for (key in abilities.keys()) {
            dashlessSlugMap.set(APIFacade.slugify(key, true), key);
        }

        for (key in itemRenames.keys()) {
            dashlessSlugMap.set(APIFacade.slugify(key, true), key);
        }
    }
}
