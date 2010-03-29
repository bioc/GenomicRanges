make_test_GRangesList <- function() {
    GRangesList(
        a =
        new("GRanges",
            seqnames = Rle(factor(c("chr1", "chr2", "chr1", "chr3")), c(1, 3, 2, 4)),
            ranges = IRanges(1:10, width = 10:1, names = head(letters, 10)),
            strand = Rle(strand(c("-", "+", "*", "+", "-")), c(1, 2, 2, 3, 2)),
            seqlengths =
            c("chr1" = NA_integer_, "chr2" = NA_integer_, "chr3" = NA_integer_),
            elementMetadata = DataFrame(score = 1:10, GC = seq(1, 0, length=10))),
        b =
        new("GRanges",
            seqnames = Rle(factor(c("chr2", "chr4", "chr5")), c(3, 6, 4)),
            ranges = IRanges(1:13, width = 13:1, names = tail(letters, 13)),
            strand = Rle(strand(c("-", "+", "-")), c(4, 5, 4)),
            seqlengths =
            c("chr2" = NA_integer_, "chr4" = NA_integer_, "chr5" = NA_integer_),
            elementMetadata = DataFrame(score = 1:13, GC = seq(0, 1, length=13))))
}

test_GRangesList_construction <- function() {
    checkException(GRangesList(IRangesList()), silent = TRUE)

    checkTrue(validObject(new("GRangesList")))
    checkTrue(validObject(GRangesList()))
    checkTrue(validObject(GRangesList(GRanges())))
    checkTrue(validObject(GRangesList(a = GRanges())))
    checkTrue(validObject(make_test_GRangesList()))
}

test_GRangesList_coercion <- function() {
    ## RangedDataList -> GRangesList
    rd <-
      RangedData(space = c(1,1,2),
                 ranges = IRanges(1:3,4:6, names = head(letters,3)),
                 strand = strand(c("+", "-", "*")),
                 score = c(10L,2L,NA))
    rdl <- RangedDataList(a = rd, b = rd)
    gr <-
      GRanges(seqnames = c(1,1,2),
              ranges = IRanges(1:3,4:6, names = head(letters,3)),
              strand = strand(c("+", "-", "*")),
              score = c(10L,2L,NA))
    grl <- GRangesList(a = gr, b = gr)
    checkIdentical(as(rdl, "GRangesList"), grl)

    ## as.data.frame
    gr1 <-
      GRanges(seqnames = c(1,1,2),
              ranges = IRanges(1:3,4:6, names = head(letters,3)),
              strand = strand(c("+", "-", "*")),
              score = c(10L,2L,NA))
    gr2 <-
      GRanges(seqnames = c("chr1", "chr2"),
              ranges = IRanges(1:2,1:2, names = tail(letters,2)),
              strand = strand(c("*", "*")),
              score = 12:13)
    grl <- GRangesList(a = gr1, b = gr2)
    df <-
      data.frame(element = rep(c("a","b"), c(3, 2)),
                 seqnames = factor(c(1,1,2,"chr1","chr2")),
                 start = c(1:3,1:2), end = c(4:6,1:2),
                 width = c(4L, 4L, 4L, 1L, 1L),
                 strand = strand(c("+", "-", "*", "*", "*")),
                 score = c(10L,2L,NA,12:13),
                 row.names = c(head(letters,3), tail(letters,2)),
                 stringsAsFactors = FALSE)
    checkIdentical(as.data.frame(grl), df)
}

test_GRangesList_accessors <- function() {
    grl <- make_test_GRangesList()
    checkIdentical(seqnames(grl), RleList(lapply(grl, seqnames), compress=TRUE))
    checkIdentical(ranges(grl), IRangesList(lapply(grl, ranges)))
    checkIdentical(strand(grl), RleList(lapply(grl, strand), compress=TRUE))
    checkIdentical(seqlengths(grl), seqlengths(grl@unlistData))
    checkIdentical(elementMetadata(grl, level="within"),
                   SplitDataFrameList(lapply(grl, elementMetadata)))
}

test_GRangesList_RangesList <- function() {
    grl <- make_test_GRangesList()
    checkIdentical(start(grl), IntegerList(lapply(grl, start)))
    checkIdentical(end(grl), IntegerList(lapply(grl, end)))
    checkIdentical(width(grl), IntegerList(lapply(grl, width)))

    ## start
    checkException(start(GRangesList()) <- NULL, silent = TRUE)
    checkException(start(make_test_GRangesList()) <- 1:26, silent = TRUE)

    grl <- make_test_GRangesList()
    orig <- start(grl)
    start(grl) <- orig + 1L
    checkIdentical(start(grl), orig + 1L)

    ## end
    checkException(end(GRangesList()) <- NULL, silent = TRUE)
    checkException(end(make_test_GRangesList()) <- 1:26, silent = TRUE)

    grl <- make_test_GRangesList()
    orig <- end(grl)
    end(grl) <- orig + 1L
    checkIdentical(end(grl), orig + 1L)

    ## width
    checkException(width(GRangesList()) <- NULL, silent = TRUE)
    checkException(width(make_test_GRangesList()) <- 1:26, silent = TRUE)

    grl <- make_test_GRangesList()
    orig <- width(grl)
    width(grl) <- orig + 1L
    checkIdentical(width(grl), orig + 1L)

    ## shift
    grl <- make_test_GRangesList()
    shifted <- shift(grl, 10)
    checkIdentical(start(grl) + 10L, start(shifted))

    ## coverage
    grl <- make_test_GRangesList()
    checkIdentical(coverage(grl),
                   RleList("chr1" = Rle(1:3, c(4, 1, 5)),
                           "chr2" = Rle(c(1L, 3L, 5L, 6L, 3L), c(1, 1, 1, 7, 3)),
                           "chr3" = Rle(0:4, c(6, 1, 1, 1, 1)),
                           "chr4" = Rle(0:6, c(3, 1, 1, 1, 1, 1, 5)),
                           "chr5" = Rle(0:4, c(9, 1, 1, 1, 1))))
    checkIdentical(coverage(grl, width = list(10, 20, 30, 40, 50)),
                   RleList("chr1" = Rle(1:3, c(4, 1, 5)),
                           "chr2" = Rle(c(1L, 3L, 5L, 6L, 3L, 0L), c(1, 1, 1, 7, 3, 7)),
                           "chr3" = Rle(c(0:4, 0L), c(6, 1, 1, 1, 1, 20)),
                           "chr4" = Rle(c(0:6, 0L), c(3, 1, 1, 1, 1, 1, 5, 27)),
                           "chr5" = Rle(c(0:4, 0L), c(9, 1, 1, 1, 1, 37))))
    checkIdentical(coverage(grl, weight = list(1L, 10L, 100L, 1000L, 10000L)),
                   RleList("chr1" = Rle(1:3, c(4, 1, 5)),
                           "chr2" = Rle(10L * c(1L, 3L, 5L, 6L, 3L), c(1, 1, 1, 7, 3)),
                           "chr3" = Rle(100L * 0:4, c(6, 1, 1, 1, 1)),
                           "chr4" = Rle(1000L * 0:6, c(3, 1, 1, 1, 1, 1, 5)),
                           "chr5" = Rle(10000L * 0:4, c(9, 1, 1, 1, 1))))
    checkIdentical(coverage(grl, shift = list(0, 1, 2, 3, 4)),
                   RleList("chr1" = Rle(1:3, c(4, 1, 5)),
                           "chr2" = Rle(c(0L, 1L, 3L, 5L, 6L, 3L), c(1, 1, 1, 1, 7, 3)),
                           "chr3" = Rle(0:4, c(8, 1, 1, 1, 1)),
                           "chr4" = Rle(0:6, c(6, 1, 1, 1, 1, 1, 5)),
                           "chr5" = Rle(0:4, c(13, 1, 1, 1, 1))))
}

test_GRangesList_Sequence <- function() {
    grl <- make_test_GRangesList()
    checkIdentical(grl, grl[])
    checkIdentical(grl[,"score"],
                   GRangesList(lapply(grl, function(x) x[,"score"])))
    checkIdentical(grl[seqnames(grl) == "chr2",],
                   GRangesList(lapply(grl, function(x) 
                                      x[seqnames(x) == "chr2",])))
    checkIdentical(grl[seqnames(grl) == "chr2", "score"],
                   GRangesList(lapply(grl, function(x) 
                                      x[seqnames(x) == "chr2", "score"])))
}