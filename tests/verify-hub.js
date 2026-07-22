const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const read = (relativePath) => fs.readFileSync(path.join(root, relativePath), "utf8");
const assert = (condition, message) => {
    if (!condition) throw new Error(message);
};

const hub = read("xaric_hub.lua");
const readme = read("README.md");
const moduleFiles = [...hub.matchAll(/file\s*=\s*"([^"]+\.lua)"/g)].map((match) => match[1]);
const releaseMatch = hub.match(/local HUB_RELEASE = "([^"]+)"/);

assert(releaseMatch, "xaric_hub.lua must define HUB_RELEASE.");
assert(moduleFiles.length > 0, "The hub script registry must contain at least one module.");
assert(new Set(moduleFiles).size === moduleFiles.length, "The hub script registry contains duplicate module filenames.");

for (const moduleFile of moduleFiles) {
    assert(fs.existsSync(path.join(root, moduleFile)), `Registered module is missing: ${moduleFile}`);
}

assert(
    readme.includes(`/xaric-hub/${releaseMatch[1]}/xaric_hub.lua`),
    "README loader must use the same pinned release as the hub."
);

for (const file of fs.readdirSync(root).filter((name) => name.endsWith(".lua"))) {
    const source = read(file);
    assert(!source.includes("sirius.menu/rayfield"), `${file} still uses an unpinned Rayfield URL.`);
    if (source.includes("Rayfield")) {
        assert(
            !source.includes("raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/"),
            `${file} must not load Rayfield from its mutable main branch.`
        );
    }
}

for (const file of ["cobalt_cheats.lua", "missiles_cheats.lua"]) {
    const source = read(file);
    assert(source.includes("restoreSpeed"), `${file} must restore modified speed values.`);
    assert(source.includes("restoreNoclip"), `${file} must restore modified collision values.`);
    assert(source.includes("Cleanup"), `${file} must expose reinjection cleanup.`);
}

console.log(`Hub integrity checks passed for ${moduleFiles.length} registered modules at ${releaseMatch[1]}.`);
