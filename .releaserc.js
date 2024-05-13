module.exports = {
  branches: ["main", "test-release"],
  ci: false,
  tagFormat: "interop-eks-microservice-chart-${version}",
  plugins: [
    [
      "@semantic-release/commit-analyzer",
      {
        preset: "angular",
        releaseRules: [
          { type: "breaking", release: "major" },
          { type: "major", release: "major" },
        ],
      },
    ],
    "@semantic-release/release-notes-generator",
    "@semantic-release/github",
  ]
};
