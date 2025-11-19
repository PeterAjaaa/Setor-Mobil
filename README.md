# 🧠 Git Guide for Our Project

Hey — welcome to the repo. This is a short, simple guide so we don’t accidentally break things or overwrite each other.

We use a simple **feature-branch workflow** — easy to follow and hard to mess up.

---

## 🌳 Branches Overview

* **`main`** → Stable, production-ready code.
* **`dev`** → Ongoing development. All features get merged here first.
* **`feature/*`** → Temporary branches for new features, fixes, or experiments.

---

## 🧩 How to Start Working on a Feature

1. **Make sure you’re up to date**

```bash
git checkout dev
git pull
```

2. **Create a new branch for your work**

```bash
git checkout -b feature/<your-feature-name>
```

Example:

```bash
git checkout -b feature/login-system
```

3. **Work, commit, and push**

```bash
# Stage and commit
git add .
git commit -m "Implement login system"

# Push your branch to remote
git push -u origin feature/<your-feature-name>
```

---

## 🔁 When You’re Done

1. On GitHub/GitLab: **Open a Pull Request**

   * **Base branch:** `dev`
   * **Compare branch:** `feature/<your-feature-name>`
   * Add a short title and description and assign a reviewer.

2. Wait for review → fix if needed → **merge into `dev`**.

3. After merge, clean up your local branch:

```bash
git checkout dev
git pull
git branch -d feature/<your-feature-name>
```

---

## 🧼 Optional: Keep Your Branch Up To Date

If `dev` changed while you were working, rebase your feature branch on top of it:

```bash
git checkout dev
git pull
git checkout feature/<your-feature-name>
git rebase dev
```

If rebase gives conflicts, resolve them, then:

```bash
git add <resolved-files>
git rebase --continue
```

After a successful rebase, push the branch (force push if necessary):

```bash
git push --force-with-lease
```

> Tip: `--force-with-lease` is safer than `--force` — it fails if someone else pushed changes you don’t have.

---

## ⚠️ Quick Rules (Do not ignore these)

* 🚫 Don’t code directly on `main` or `dev`.
* 🌱 Always branch off from `dev`.
* 🧍‍♂️ One feature = one branch = one PR.
* 🔍 PRs must be reviewed before merging.
* 🧹 Delete feature branches after merging.

---

## 💡 Example Workflow (copy-paste)

```bash
# Start work
git checkout dev
git pull
git checkout -b feature/add-dark-mode

# Work, commit, push
git add .
git commit -m "Add dark mode UI"
git push -u origin feature/add-dark-mode

# Open PR → review → merge

# Cleanup
git checkout dev
git pull
git branch -d feature/add-dark-mode
```

---

## 🆘 If You’re Stuck

Just ping the other dev in the PR or message us directly. Don’t push to `dev` or `main` if you’re unsure — ask first.

## TODO

* Change rating calculation from client-side calculation to data from API
* Add OTP screens
* Implement the search bar in home screen
* Implement correct 'number of order' in the rating system in the vehicle detail screen
