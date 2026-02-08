#!/usr/bin/env python3
"""
show_gym_stats.py

Display statistics about the gym database and any validation results.
"""

import sqlite3
import sys
import json
from collections import Counter

def show_stats(sqlite_path: str = "gyms.sqlite"):
    """Show database statistics"""
    conn = sqlite3.connect(sqlite_path)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    
    print("=" * 80)
    print("CLIMBING GYM DATABASE STATISTICS")
    print("=" * 80)
    print()
    
    # Total gyms
    cur.execute("SELECT COUNT(*) as count FROM gyms")
    total = cur.fetchone()["count"]
    print(f"Total gyms in database: {total}")
    print()
    
    # Gyms by state
    print("Gyms by State:")
    print("-" * 40)
    cur.execute("""
        SELECT state, COUNT(*) as count 
        FROM gyms 
        WHERE state IS NOT NULL
        GROUP BY state 
        ORDER BY count DESC 
        LIMIT 15
    """)
    for row in cur.fetchall():
        state = row["state"] or "Unknown"
        count = row["count"]
        bar = "█" * min(50, count)
        print(f"  {state:3s}  {count:4d}  {bar}")
    print()
    
    # Gyms by source
    print("Gyms by Data Source:")
    print("-" * 40)
    cur.execute("""
        SELECT source, COUNT(*) as count 
        FROM gyms 
        GROUP BY source 
        ORDER BY count DESC
    """)
    for row in cur.fetchall():
        source = row["source"] or "Unknown"
        count = row["count"]
        pct = count / total * 100 if total > 0 else 0
        print(f"  {source:20s}  {count:4d}  ({pct:5.1f}%)")
    print()
    
    # Data completeness
    print("Data Completeness:")
    print("-" * 40)
    fields = [
        ("name", "Name"),
        ("street", "Street Address"),
        ("city", "City"),
        ("state", "State"),
        ("postcode", "Zip Code"),
        ("phone", "Phone"),
        ("website", "Website"),
        ("latitude", "Coordinates"),
        ("hours", "Hours")
    ]
    
    for field, label in fields:
        cur.execute(f"SELECT COUNT(*) as count FROM gyms WHERE {field} IS NOT NULL AND {field} != ''")
        count = cur.fetchone()["count"]
        pct = count / total * 100 if total > 0 else 0
        bar = "█" * int(pct / 2)
        print(f"  {label:20s}  {count:4d}/{total:4d}  ({pct:5.1f}%)  {bar}")
    print()
    
    # Check for validation results
    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='validation_results'")
    if cur.fetchone():
        print("=" * 80)
        print("VALIDATION RESULTS")
        print("=" * 80)
        print()
        
        # Most recent validation
        cur.execute("SELECT MAX(validation_date) as last_validation FROM validation_results")
        last = cur.fetchone()["last_validation"]
        if last:
            print(f"Last validation run: {last}")
            print()
        
        # Validation summary
        cur.execute("""
            SELECT status, COUNT(*) as count
            FROM validation_results
            WHERE validation_date = (SELECT MAX(validation_date) FROM validation_results)
            GROUP BY status
            ORDER BY count DESC
        """)
        
        validation_results = cur.fetchall()
        if validation_results:
            print("Latest Validation Status:")
            print("-" * 40)
            
            total_validated = sum(row["count"] for row in validation_results)
            
            status_emoji = {
                "valid": "✓",
                "updated": "⟳",
                "closed": "✗",
                "moved": "→",
                "not_found": "?",
                "error": "!"
            }
            
            for row in validation_results:
                status = row["status"]
                count = row["count"]
                pct = count / total_validated * 100 if total_validated > 0 else 0
                emoji = status_emoji.get(status, "•")
                print(f"  {emoji} {status.capitalize():15s}  {count:4d}  ({pct:5.1f}%)")
            print()
        
        # Gyms needing attention
        cur.execute("""
            SELECT g.id, g.name, g.city, g.state, v.status, v.changes
            FROM gyms g
            JOIN validation_results v ON g.id = v.gym_id
            WHERE v.status IN ('closed', 'moved', 'not_found')
              AND v.validation_date = (SELECT MAX(validation_date) FROM validation_results)
            ORDER BY v.status, g.state, g.name
            LIMIT 20
        """)
        
        problem_gyms = cur.fetchall()
        if problem_gyms:
            print("Gyms Needing Attention:")
            print("-" * 40)
            for row in problem_gyms:
                name = row["name"]
                city = row["city"] or "?"
                state = row["state"] or "?"
                status = row["status"]
                changes_json = row["changes"]
                
                status_emoji = {
                    "closed": "✗",
                    "moved": "→",
                    "not_found": "?"
                }
                emoji = status_emoji.get(status, "!")
                
                print(f"  {emoji} [{status.upper():10s}] {name} ({city}, {state})")
                
                if changes_json:
                    try:
                        changes = json.loads(changes_json)
                        for change in changes[:2]:  # Show first 2 changes
                            print(f"      → {change}")
                    except:
                        pass
            
            if len(problem_gyms) == 20:
                cur.execute("""
                    SELECT COUNT(*) as count
                    FROM validation_results
                    WHERE status IN ('closed', 'moved', 'not_found')
                      AND validation_date = (SELECT MAX(validation_date) FROM validation_results)
                """)
                total_problems = cur.fetchone()["count"]
                print(f"\n  ... and {total_problems - 20} more")
            print()
    
    # Coverage by state
    print("=" * 80)
    print("TOP CLIMBING DESTINATIONS")
    print("=" * 80)
    print()
    
    cur.execute("""
        SELECT state, city, COUNT(*) as count 
        FROM gyms 
        WHERE state IS NOT NULL AND city IS NOT NULL
        GROUP BY state, city 
        HAVING count >= 3
        ORDER BY count DESC 
        LIMIT 15
    """)
    
    cities = cur.fetchall()
    if cities:
        print("Cities with Most Climbing Gyms:")
        print("-" * 40)
        for row in cities:
            city = row["city"]
            state = row["state"]
            count = row["count"]
            bar = "█" * min(20, count * 2)
            print(f"  {city}, {state:2s}  {count:2d} gyms  {bar}")
    print()
    
    conn.close()
    
    print("=" * 80)


if __name__ == "__main__":
    sqlite_path = sys.argv[1] if len(sys.argv) > 1 else "gyms.sqlite"
    show_stats(sqlite_path)

