#!/usr/bin/env python3
"""
Converts aus-con-leads.csv into two text files the ZeroClaw agent can parse reliably.

Usage: python3 scripts/prepare-leads.py

Outputs:
  workspace/memory/lead-index.txt   — Name | Company | Role | Email (one line per lead)
  workspace/memory/lead-details.txt — Full structured records for ingestion
"""

import csv
import os
import re

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
CSV_PATH = os.path.join(PROJECT_DIR, "workspace", "memory", "aus-con-leads.csv")
INDEX_PATH = os.path.join(PROJECT_DIR, "workspace", "memory", "lead-index.txt")
DETAILS_PATH = os.path.join(PROJECT_DIR, "workspace", "memory", "lead-details.txt")


def clean_text(text):
    """Collapse multi-line text into a single line."""
    if not text:
        return ""
    return re.sub(r"\s+", " ", text).strip()


def main():
    with open(CSV_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        leads = []
        skipped = 0

        for row in reader:
            name = (row.get("Full Name") or "").strip()
            company = (row.get("Company Name") or "").strip()
            email = (row.get("Work Email") or "").strip()

            if not name or not company or not email:
                skipped += 1
                continue

            website = (row.get("Company Domain") or "").strip()
            if website and not website.startswith("http"):
                website = "https://" + website

            leads.append({
                "name": name,
                "company": company,
                "role": (row.get("Job Title") or "").strip(),
                "email": email,
                "website": website,
                "location": (row.get("Location") or "").strip(),
                "linkedin": (row.get("LinkedIn Profile") or "").strip(),
                "headline": clean_text(row.get("Headline") or ""),
                "summary": clean_text(row.get("Summary") or ""),
            })

    # Write lead-index.txt
    with open(INDEX_PATH, "w", encoding="utf-8") as f:
        for lead in leads:
            f.write(f"{lead['name']} | {lead['company']} | {lead['role']} | {lead['email']}\n")

    # Write lead-details.txt
    with open(DETAILS_PATH, "w", encoding="utf-8") as f:
        for lead in leads:
            f.write("=== LEAD ===\n")
            f.write(f"Name: {lead['name']}\n")
            f.write(f"Company: {lead['company']}\n")
            f.write(f"Role: {lead['role']}\n")
            f.write(f"Email: {lead['email']}\n")
            if lead["website"]:
                f.write(f"Website: {lead['website']}\n")
            if lead["location"]:
                f.write(f"Location: {lead['location']}\n")
            if lead["linkedin"]:
                f.write(f"LinkedIn: {lead['linkedin']}\n")
            if lead["headline"]:
                f.write(f"Headline: {lead['headline']}\n")
            if lead["summary"]:
                f.write(f"Summary: {lead['summary']}\n")
            f.write("\n")

    print(f"Processed {len(leads)} leads ({skipped} skipped — missing name/company/email)")
    print(f"  {INDEX_PATH}")
    print(f"  {DETAILS_PATH}")


if __name__ == "__main__":
    main()
