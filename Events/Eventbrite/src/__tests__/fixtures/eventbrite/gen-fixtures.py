#!/usr/bin/env python3
"""
Eventbrite fixture generator (PII-SCRUBBED, mocked-only — NOT live captures).

Emits, per Integration Object family, the response shapes documented in the
Eventbrite Platform API v3 (apiary spec, 2024-02-16). Every shape mirrors the
documented envelope: the per-resource list key (events/attendees/orders/...) +
a `pagination` object. PII (attendee/buyer name, email, barcode, custom answers)
is scrubbed to the test ranges per .claude/rules/connector-test-conventions.md.

These are FIXTURES for the credential-free T4/T5 vitest tier — no network, no
real records. Run:  python3 gen-fixtures.py
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))

# Scrubbed, fixed test values (never PII).
EMAIL = "example+1@example.com"
EMAIL2 = "example+2@example.com"
NAME = "<scrubbed-name-1>"
NAME2 = "<scrubbed-name-2>"
ADDR = "123 Test St"
PHONE = "555-0101"
BARCODE = "0000000000001"  # scrubbed barcode (was attendee barcode PII)

def cur(major=10, code="USD"):
    return {"currency": code, "value": major * 100, "major_value": f"{major}.00", "display": f"${major}.00"}

def pagination(has_more, cont, page=1, page_count=2, count=3):
    return {
        "object_count": count,
        "page_number": page,
        "page_size": 50,
        "page_count": page_count,
        "has_more_items": has_more,
        "continuation": cont,
    }

def write(name, obj):
    path = os.path.join(HERE, name)
    with open(path, "w") as f:
        json.dump(obj, f, indent=2)
        f.write("\n")
    print("wrote", name)

# ── Representative single records per family (documented v3 shapes, scrubbed) ──

REC = {
    "User": {
        "id": "210000000001",
        "name": NAME,
        "first_name": NAME.split("-")[0],
        "last_name": NAME2,
        "emails": [{"email": EMAIL, "verified": True, "primary": True}],
        "is_public": False,
    },
    "Organization": {
        "id": "330000000001",
        "name": "<scrubbed-org-1>",
        "vertical": "default",
        "image_id": None,
        "_type": "organization",
    },
    "OrganizationMember": {
        "id": "440000000001",
        "user_id": "210000000002",
        "email": EMAIL2,
        "role": "Owner",
        "name": NAME2,
        "first_name": NAME2.split("-")[0],
        "last_name": "<scrubbed-name-3>",
        "status": "active",
        "created": "2026-03-01T10:00:00Z",
    },
    "Event": {
        "id": "550000000001",
        "name": {"text": "Test Event", "html": "Test Event"},
        "description": {"text": "<redacted>", "html": "<redacted>"},
        "url": "https://www.eventbrite.com/e/test-event-tickets-550000000001",
        "start": {"timezone": "UTC", "local": "2026-07-01T18:00:00", "utc": "2026-07-01T18:00:00Z"},
        "end": {"timezone": "UTC", "local": "2026-07-01T21:00:00", "utc": "2026-07-01T21:00:00Z"},
        "created": "2026-04-01T12:00:00Z",
        "changed": "2026-04-10T09:30:00Z",
        "published": "2026-04-02T08:00:00Z",
        "status": "live",
        "currency": "USD",
        "online_event": False,
        "organization_id": "330000000001",
        "organizer_id": "660000000001",
        "venue_id": "770000000001",
        "category_id": "103",
        "subcategory_id": "3001",
        "format_id": "1",
        "capacity": 200,
        "is_free": False,
    },
    "EventSeries": {
        "id": "550000000002",
        "name": {"text": "Test Series Event", "html": "Test Series Event"},
        "series_id": "880000000001",
        "is_series": True,
        "is_series_parent": False,
        "start": {"timezone": "UTC", "local": "2026-08-01T18:00:00", "utc": "2026-08-01T18:00:00Z"},
        "end": {"timezone": "UTC", "local": "2026-08-01T21:00:00", "utc": "2026-08-01T21:00:00Z"},
        "changed": "2026-05-01T09:30:00Z",
        "status": "live",
    },
    "Venue": {
        "id": "770000000001",
        "name": "Test Venue",
        "address": {
            "address_1": ADDR,
            "address_2": None,
            "city": "Example",
            "region": "XX",
            "postal_code": "00000",
            "country": "US",
            "latitude": "0.0",
            "longitude": "0.0",
        },
        "latitude": "0.0",
        "longitude": "0.0",
        "organizer_id": "660000000001",
    },
    "Organizer": {
        "id": "660000000001",
        "name": "<scrubbed-org-1>",
        "description": {"text": "<redacted>", "html": "<redacted>"},
        "url": "https://www.eventbrite.com/o/test-organizer-660000000001",
        "num_past_events": 5,
        "num_future_events": 2,
    },
    "TicketClass": {
        "id": "990000000001",
        "name": "General Admission",
        "description": "<redacted>",
        "cost": cur(25),
        "fee": cur(2),
        "tax": cur(0),
        "quantity_total": 100,
        "quantity_sold": 10,
        "free": False,
        "donation": False,
        "hidden": False,
        "event_id": "550000000001",
    },
    "TicketGroup": {
        "id": "111000000001",
        "name": "VIP Group",
        "status": "live",
        "event_ticket_ids": {"550000000001": ["990000000001"]},
    },
    "Order": {
        "id": "122000000001",
        "created": "2026-06-01T15:00:00Z",
        "changed": "2026-06-01T15:05:00Z",
        "name": NAME,
        "first_name": NAME.split("-")[0],
        "last_name": NAME2,
        "email": EMAIL,  # buyer email — scrubbed
        "status": "placed",
        "event_id": "550000000001",
        "costs": {"base_price": cur(25), "gross": cur(27)},
    },
    "Attendee": {
        "id": "133000000001",
        "created": "2026-06-01T15:00:00Z",
        "changed": "2026-06-01T15:05:00Z",
        "ticket_class_id": "990000000001",
        "ticket_class_name": "General Admission",
        "order_id": "122000000001",
        "event_id": "550000000001",
        "status": "Attending",
        "checked_in": False,
        "barcodes": [{"barcode": BARCODE, "status": "unused"}],  # barcode — scrubbed
        "profile": {
            "name": NAME,
            "first_name": NAME.split("-")[0],
            "last_name": NAME2,
            "email": EMAIL,  # attendee email — scrubbed
        },
        "answers": [
            {"question_id": "144000000001", "question": "Dietary?", "answer": "<redacted>", "type": "text"}
        ],
    },
    # Answer is an EXPANSION-ONLY object reached via attendees[] -> answers[]; its list
    # fixture is therefore an attendees envelope whose records each carry id + answers[]
    # (the connector's NormalizeResponse unwraps the `attendees` key; answers are descended
    # downstream). PK is DEFERRED (matrix: Answer PKVerdict=defer) — answers carry no own id.
    "Answer": {
        "id": "133000000099",
        "event_id": "550000000001",
        "answers": [
            {
                "question_id": "144000000001",
                "question": "Dietary preference?",
                "answer": "<redacted>",  # custom answer — scrubbed PII
                "type": "text",
            }
        ],
    },
    "Discount": {
        "id": "155000000001",
        "code": "TESTDISCOUNT",
        "type": "coded",
        "amount_off": None,
        "percent_off": "10.00",
        "quantity_available": 50,
        "quantity_sold": 3,
        "event_id": "550000000001",
    },
    "Question": {
        "id": "144000000001",
        "question": {"text": "Dietary preference?", "html": "Dietary preference?"},
        "type": "text",
        "required": False,
        "event_id": "550000000001",
        "respondent": "attendee",
    },
    "Category": {
        "id": "103",
        "name": "Music",
        "name_localized": "Music",
        "short_name": "Music",
        "subcategories": [{"id": "3001", "name": "Alternative"}],
    },
    "Subcategory": {
        "id": "3001",
        "name": "Alternative",
        "parent_category": {"id": "103", "name": "Music"},
    },
    "Format": {
        "id": "1",
        "name": "Conference",
        "name_localized": "Conference",
        "short_name": "Conference",
        "short_name_localized": "Conference",
    },
    "Media": {
        "id": "166000000001",
        "url": "https://img.evbuc.com/test-image.jpg",
        "crop_mask": None,
        "original": {"url": "https://img.evbuc.com/test-image-original.jpg", "width": 1200, "height": 800},
    },
    "Webhook": {
        "id": "177000000001",
        "endpoint_url": "https://example.com/eventbrite/hook",
        "actions": ["order.placed", "event.published"],
        "event_id": None,
        "organization_id": "330000000001",
    },
    "EventTeam": {
        "id": "188000000001",
        "name": "Door Staff",
        "date_created": "2026-04-01T12:00:00Z",
        "event_id": "550000000001",
        "attendee_count": 4,
    },
    "InventoryTier": {
        "id": "199000000001",
        "name": "Tier 1",
        "quantity_total": 100,
        "sort_order": 1,
        "event_id": "550000000001",
        "holds": [],
    },
}

# ResponseDataKey per family (null → single-record/no-envelope detail object).
LIST_KEY = {
    "User": None, "Organization": "organizations", "OrganizationMember": "members",
    "Event": "events", "EventSeries": "events", "Venue": "venues", "Organizer": None,
    "TicketClass": "ticket_classes", "TicketGroup": "ticket_groups", "Order": "orders",
    "Attendee": "attendees", "Answer": "attendees", "Discount": "discounts",
    "Question": "questions", "Category": "categories", "Subcategory": "subcategories",
    "Format": "formats", "Media": None, "Webhook": "webhooks", "EventTeam": "teams",
    "InventoryTier": "inventory_tiers",
}

# Families that declare a create (per metadata) → need a create-response fixture.
CREATE = {"Event", "Venue", "TicketClass", "TicketGroup", "Discount", "Question",
          "Media", "Webhook", "EventTeam", "InventoryTier"}
# Families that declare a delete → need a delete-response fixture.
DELETE = {"Event", "TicketGroup", "Discount", "Question", "Webhook", "InventoryTier"}


def slug(name):
    # camelCase → kebab
    out = []
    for i, ch in enumerate(name):
        if ch.isupper() and i > 0:
            out.append("-")
        out.append(ch.lower())
    return "".join(out)


def make_list(name, rec, has_more, cont):
    key = LIST_KEY[name]
    if key is None:
        # No envelope — bare detail object (User/Organizer/Media/Format-detail).
        return rec
    # Two-record list so a list fixture is plural.
    rec2 = dict(rec)
    if "id" in rec2:
        rec2["id"] = str(int(rec2["id"]) + 1) if rec2["id"].isdigit() else rec2["id"] + "2"
    body = {key: [rec, rec2], "pagination": pagination(has_more, cont)}
    return body


for name, rec in REC.items():
    s = slug(name)
    # 1. happy-path list/detail (final page — has_more_items=false)
    write(f"{s}-list.json", make_list(name, rec, has_more=False, cont="cont_final_token"))
    # 2. pagination fixture (has_more_items=true + continuation cursor)
    write(f"{s}-list-page1.json", make_list(name, rec, has_more=True, cont="cont_next_page_token_abc123"))
    # single detail (always useful for GetRecord / NormalizeResponse bare-object case)
    write(f"{s}-single.json", rec)
    # 3. error fixture (404 NOT_FOUND or 429 HIT_RATE_LIMIT)
    if name in ("Order", "Attendee", "Webhook"):
        write(f"{s}-error-429.json",
              {"error": "HIT_RATE_LIMIT", "error_description": "The rate limit has been reached for this token.", "status_code": 429})
    else:
        write(f"{s}-error-404.json",
              {"error": "NOT_FOUND", "error_description": f"The {name} you requested does not exist.", "status_code": 404})
    # create-response fixture (POST → body.id) for write-capable families
    if name in CREATE:
        created = dict(rec)
        write(f"{s}-create-response.json", created)
    # delete-response fixture for families that declare delete
    if name in DELETE:
        write(f"{s}-delete-response.json", {"deleted": True})

print("DONE")
