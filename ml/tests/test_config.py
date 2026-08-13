from __future__ import annotations

import copy
import unittest

from ml.tools.validate_config import (
    DEFAULT_CANDIDATES,
    DEFAULT_CLASSES,
    ConfigError,
    load_yaml,
    validate_candidates,
    validate_classes,
)
from ml.tools.download_pilot import (
    DEFAULT_SOURCES,
    license_is_allowed,
    validate_sources,
)
from ml.tools.download_openimages_pilot import (
    DEFAULT_CONFIG as DEFAULT_OPENIMAGES_CONFIG,
    validate_config as validate_openimages_config,
)
from ml.tools.evaluate_tinyclip_pilot import (
    DEFAULT_PROMPTS as DEFAULT_TINYCLIP_PROMPTS,
    validate_prompt_config,
)


class ClassesConfigTest(unittest.TestCase):
    def setUp(self) -> None:
        self.document = load_yaml(DEFAULT_CLASSES)

    def test_repository_catalog_is_valid(self) -> None:
        report = validate_classes(self.document)

        self.assertEqual(self.document["fallback_id"], report["ordered_active_ids"][-1])
        self.assertEqual(len(report["ordered_active_ids"]), report["output_count"])
        self.assertEqual(64, len(report["catalog_sha256"]))

    def test_pipeline_accepts_future_classes_without_a_code_change(self) -> None:
        original_report = validate_classes(self.document)
        extended = copy.deepcopy(self.document)
        fallback = extended["classes"].pop()
        for class_id, display_name in (("mapache", "Mapache"), ("erizo", "Erizo")):
            extended["classes"].append(
                {
                    "id": class_id,
                    "display_name": display_name,
                    "category": "zoo",
                    "active": True,
                    "include": [class_id],
                    "exclude": [],
                }
            )
        extended["classes"].append(fallback)
        extended["catalog_version"] += 1

        extended_report = validate_classes(extended)

        self.assertEqual(original_report["output_count"] + 2, extended_report["output_count"])
        self.assertNotEqual(original_report["catalog_sha256"], extended_report["catalog_sha256"])

    def test_rejects_duplicate_ids(self) -> None:
        duplicate = copy.deepcopy(self.document)
        duplicate["classes"].insert(1, copy.deepcopy(duplicate["classes"][0]))

        with self.assertRaisesRegex(ConfigError, "duplicado"):
            validate_classes(duplicate)


class CandidatesConfigTest(unittest.TestCase):
    def test_repository_candidates_are_valid(self) -> None:
        catalog = validate_classes(load_yaml(DEFAULT_CLASSES))
        counts = validate_candidates(
            load_yaml(DEFAULT_CANDIDATES), catalog["catalog_version"]
        )

        self.assertGreaterEqual(counts["admitted"], 2)
        self.assertGreaterEqual(counts["rejected"], 1)

    def test_rejects_admitted_external_weights(self) -> None:
        candidates = load_yaml(DEFAULT_CANDIDATES)
        admitted = next(
            candidate
            for candidate in candidates["candidates"]
            if candidate["status"] == "admitted"
        )
        admitted["weights_license"] = "unknown"

        with self.assertRaisesRegex(ConfigError, "licencia permisiva"):
            validate_candidates(candidates, candidates["catalog_version"])


class SourcesConfigTest(unittest.TestCase):
    def test_repository_sources_cover_extensible_catalog(self) -> None:
        report = validate_sources(load_yaml(DEFAULT_SOURCES), load_yaml(DEFAULT_CLASSES))

        self.assertEqual(29, report["catalog"]["output_count"])
        self.assertEqual(
            "https://api.inaturalist.org/v1/observations",
            report["source"]["api_url"],
        )

    def test_rejects_missing_class_query(self) -> None:
        sources = load_yaml(DEFAULT_SOURCES)
        sources["classes"].pop("caballo")

        with self.assertRaisesRegex(ConfigError, "faltan=.*caballo"):
            validate_sources(sources, load_yaml(DEFAULT_CLASSES))

    def test_license_policy_requires_explicit_permissive_license(self) -> None:
        allowed = ["cc0", "cc-by", "cc-by-sa"]

        self.assertTrue(license_is_allowed("cc-by-sa", allowed))
        self.assertFalse(license_is_allowed("cc-by-nc", allowed))
        self.assertFalse(license_is_allowed("cc-by-nd", allowed))


class OpenImagesPilotConfigTest(unittest.TestCase):
    def test_repository_config_covers_every_animal_with_five_images(self) -> None:
        report = validate_openimages_config(
            load_yaml(DEFAULT_OPENIMAGES_CONFIG), load_yaml(DEFAULT_CLASSES)
        )

        self.assertEqual(5, report["target"])
        self.assertEqual(29, report["catalog"]["output_count"])
        self.assertEqual({5}, set(report["source_counts"].values()))

    def test_rejects_incomplete_hybrid_class(self) -> None:
        config = load_yaml(DEFAULT_OPENIMAGES_CONFIG)
        config["reviewed_inaturalist"]["oveja"].pop()

        with self.assertRaisesRegex(ConfigError, "Cada animal necesita 5"):
            validate_openimages_config(config, load_yaml(DEFAULT_CLASSES))


class TinyClipPromptConfigTest(unittest.TestCase):
    def test_repository_prompts_cover_the_catalog(self) -> None:
        report = validate_prompt_config(
            load_yaml(DEFAULT_TINYCLIP_PROMPTS), load_yaml(DEFAULT_CLASSES)
        )

        self.assertEqual(29, len(report["prompts"]))
        self.assertEqual(
            "wkcn/TinyCLIP-ViT-8M-16-Text-3M-YFCC15M", report["model"]["id"]
        )

    def test_rejects_a_missing_future_class_prompt(self) -> None:
        prompts = load_yaml(DEFAULT_TINYCLIP_PROMPTS)
        prompts["classes"].pop("koala")

        with self.assertRaisesRegex(ConfigError, "faltan=.*koala"):
            validate_prompt_config(prompts, load_yaml(DEFAULT_CLASSES))


if __name__ == "__main__":
    unittest.main()
